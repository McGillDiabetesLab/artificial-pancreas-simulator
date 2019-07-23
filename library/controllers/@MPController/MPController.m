classdef MPController < InfusionController
    %MPCONTROLLER  Model predictive controller.
    %   This is an implementation of a model predictive control strategy
    %   for the artificial pancreas. In this MPC implementation, we use a
    %   predefined type 1 patient model based on the Bergman model and a
    %   Kalman filter for state space estimation.
    %
    %   For more details, see
    %   A. E. Fathi, M. R. Smaoui, V. Gingras, B. Boulet, and A. Haidar,
    %   "The Artificial Pancreas and Meal Control: An Overview of
    %   Postprandial Glucose Regulation in Type 1 Diabetes," IEEE Control
    %   Systems, vol. 38, no. 1, pp. 67-85, Feb. 2018.
    %
    %   If you use this controller in published material please refer
    %   properlly to the above paper and a link to the Github repository.
    %
    
    properties(GetAccess = public, SetAccess = immutable)
        historySize = 1000;
        
        % State enumeration.
        eGs = 1;
        eGp = 2;
        eEGP = 3;
        eIp = 4;
        eQb = 5;
        eUm = 6;
        eQm = 7;
        
        stateNames = { ...
            'Glucose sensor (mmol/L)', ...
            'Glucose plasma (mmol/L)', ...
            'Endogenous glucose production flux (mmol / (L min))', ...
            'Plasma insulin quantity (U)', ...
            'Subcutaneous insulin quantity (U)', ...
            'Digested meal (g)', ...
            'Consumed meal (g)'};
    end
    
    properties(GetAccess = public, SetAccess = protected)
        opt;
        
        U; % History of control actions.
        ULast; % Last control action (U: [basal insulin, bolus insulin, meal]).
        UULast; % Last predicted control action vector for basal insulin.
        
        Y; % History of glucose measurements.
        YLast; % Last glucose measurement.
        
        X; % History of state estimates.
        XLast; % Last state estimate.
        
        P; % History of state covariance matrices.
        PLast; % Last state covariance matrix.
        
        debug = false; % Flag that enables debug information in the results.
    end
    
    properties(GetAccess = protected, SetAccess = protected)
        init; % Structure holding initialization parameters received from the patient.
        param; % Structure holding patient parameters.
        
        mpcParam; % Structure holding MPC specific parameters.
        kalmanParam; % Structure holding Kalman filter specific parameters.
        
        counter; % Counting number of times getInfusions is called.
        currentTime; % Current simulation time.
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            if ~exist('lastOptions', 'var')
                lastOptions = struct();
                lastOptions.name = className;
                lastOptions.gain = 1.0;
                lastOptions.debugInfo = false;
            end
            
            dlgTitle = 'Configure Model Predictive Controller';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Controller name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200;
            
            prompt(end+1, :) = {'Aggressiveness:', 'gain', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 100;
            
            prompt(end+1, :) = {'Show debug information.', 'debugInfo', []};
            formats(end+1, 1).type = 'check';
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, lastOptions);
            
            options = [];
            if ~cancelled
                options = answer;
            end
        end
    end
    
    methods
        function this = MPController(simulationStartTime, simulationDuration, simulationStepSize, patient, options)
            this@InfusionController(simulationStartTime, simulationDuration, simulationStepSize, patient);
            
            % Parse options.
            this.opt.name = this.name;
            this.opt.gain = 1.0;
            this.opt.debugInfo = false;
            
            if exist('options', 'var')
                f = fields(this.opt);
                for i = 1:numel(f)
                    if isfield(options, f{i})
                        this.opt.(f{i}) = options.(f{i});
                    end
                end
            end
            
            this.name = this.opt.name;
            this.mpcParam.factor = this.opt.gain;
            this.debug = this.opt.debugInfo;
            
            % Initialize counter.
            this.counter = 0;
        end
        
        function infusions = getInfusions(this, time)
            if this.counter == 0
                this.initialization();
            end
            
            % Update local current time.
            this.currentTime = time;
            
            % Get last measurement.
            this.YLast = this.patient.getGlucoseMeasurement();
            this.Y(:, 1:end-1) = this.Y(:, 2:end);
            this.Y(:, end) = this.YLast;
            
            % Kalman state estimate.
            X0 = this.getStateEstimate();
            
            % Apply bolus in case of meals.
            XMealBolus = zeros(size(X0));
            meal = this.patient.getMeal(time);
            if meal.value > 0
                carbFactor = this.init.CarbsF(floor(mod(time, 24*60)/this.simulationStepSize)+1);
                corrBolus = (this.YLast - this.param.GTarg) / this.param.Si;
                
                if corrBolus < 0.1 % if less than target give a free 15g
                    bolus = round(max((meal.value - 15.0)/carbFactor-max(this.getIOB, 0), 0), 1);
                else
                    bolus = round(max(meal.value/carbFactor+corrBolus-max(this.getIOB, 0), 0), 1);
                end
                
                XMealBolus(this.eQb) = bolus;
                XMealBolus(this.eQm) = meal.value;
                
                infusions.bolusInsulin = bolus;
            else
                infusions.bolusInsulin = 0;
            end
            
            % Get basal insulin.
            Ub = this.init.Basals(floor(mod( ...
                time:this.simulationStepSize:time+(this.mpcParam.MStep - 1)*this.simulationStepSize, ...
                24*60)/this.simulationStepSize)+1);
            Ub = Ub(:);
            
            if all(isnan(this.Y(end-2:end)))
                infusions.basalInsulin = Ub(1);
            else
                % Get gains and limits.
                [Gy, Gu, UbMin, UbMax] = getMPCGains(this, Ub);
                
                % Construct optimization matrices.
                [H, f] = this.getMPCMatrices(X0+XMealBolus, Ub, Gy, Gu);
                
                % Solve quadratic program.
                [this.UULast, ~] = quadprog( ...
                    H, ...
                    f, ...
                    -this.mpcParam.CC*this.mpcParam.BB, ...
                    this.mpcParam.CC*this.mpcParam.AA*(X0 + XMealBolus)+this.mpcParam.CC*this.mpcParam.BB*Ub-this.param.GHypo, ...
                    [], ...
                    [], ...
                    UbMin, ...
                    UbMax, ...
                    zeros(this.mpcParam.MStep, 1), ...
                    this.mpcParam.quadprogOpt);
                
                if ~isempty(this.UULast)
                    ui = this.UULast(1);
                    infusions.basalInsulin = round(100*(ui + Ub(1))) / 100;
                else
                    infusions.basalInsulin = 0;
                end
            end
            
            % Save the control action U.
            this.ULast = [infusions.basalInsulin; ...
                infusions.bolusInsulin; ...
                meal.value];
            this.U(:, 1:end-1) = this.U(:, 2:end);
            this.U(:, end) = this.ULast;
            
            this.counter = this.counter + 1;
        end
        
        function setInfusions(this, time, infusions)
            if isfield(infusions, 'basalInsulin')
                this.ULast(1) = infusions.basalInsulin;
            end
            if isfield(infusions, 'bolusInsulin')
                this.ULast(2) = infusions.bolusInsulin;
            end
            this.U(:, end) = this.ULast;
        end
        
        function plotDebugInfo(this, figureId)
            if isempty(this.currentTime)
                return;
            end
            
            figure(figureId);
            
            N = (this.currentTime - this.simulationStartTime) / this.simulationStepSize;
            EGPFlux = 60 * this.X(this.eEGP, end-N:end);
            insulinFlux = 60 * this.param.Si .* this.X(this.eIp, end-N:end) ./ this.param.Taui;
            mealFlux = 60 * this.param.Km * this.X(this.eUm, end-N:end) ./ this.param.Taum;
            
            plot(this.simulationStepSize*(0:1:N)+this.simulationStartTime, EGPFlux, ...
                'color', [139, 0, 139]/255, ...
                'LineStyle', '--', ...
                'LineWidth', 2.0, ...
                'Marker', 'none', ...
                'DisplayName', sprintf('%s (%s)', this.stateNames{this.eEGP}, this.name));
            
            plot(this.simulationStepSize*(0:1:N)+this.simulationStartTime, insulinFlux, ...
                'color', [173, 255, 47]/255, ...
                'LineStyle', '--', ...
                'LineWidth', 2.0, ...
                'Marker', 'none', ...
                'DisplayName', sprintf('%s (%s)', this.stateNames{this.eIp}, this.name));
            
            plot(this.simulationStepSize*(0:1:N)+this.simulationStartTime, mealFlux, ...
                'color', [255, 215, 0]/255, ...
                'LineStyle', '--', ...
                'LineWidth', 2.0, ...
                'Marker', 'none', ...
                'DisplayName', sprintf('%s (%s)', this.stateNames{this.eUm}, this.name));
            
            [tt, yy, yy0] = this.getGlucosePredictions();
            plot([this.currentTime; tt(:)], [this.XLast(this.eGp); yy(:)], ...
                '--c', ...
                'linewidth', 1.5, ...
                'marker', 'none', ...
                'DisplayName', sprintf('Predicted %s (%s)', this.stateNames{this.eGp}, this.name));
            plot([this.currentTime; tt(:)], [this.XLast(this.eGp); yy0(:)], ...
                '--r', ...
                'linewidth', 1.5, ...
                'marker', 'none', ...
                'DisplayName', sprintf('Free %s (%s)', this.stateNames{this.eGp}, this.name));
        end
        
        function iob = getIOB(this)
            Ub = this.init.Basals(floor(mod(this.currentTime, 24*60)/this.simulationStepSize)+1);
            
            iob = sum(this.XLast(this.eIp:this.eQb)) - 2 * Ub;
        end
    end
    
    methods(Access = private)
        function initialization(this)
            % Get patient properties.
            prop = this.patient.getProperties();
            
            % Initialize variables.
            % An estimation of TDD (Total daily dose) is mandatory.
            % Patient should either have a field for TDD, or daily basal rates.
            if isfield(prop, 'TDD')
                this.init.TDD = prop.TDD; % U.
            elseif isfield(prop, 'pumpBasals')
                TDB = sum(conv2([prop.pumpBasals.time, 1440], [1, -1], 'valid').*prop.pumpBasals.value) / 60;
                this.init.TDD = TDB / 0.45; % U.
            elseif isfield(prop, 'TDB')
                this.init.TDD = prop.TDB / 0.45; % U.
            else
                error('Couldn''t find patient TDD, will abort!')
            end
            
            % this.init.Basals holds the pumpBasals values for the day
            % from midnight to next day's midnight (exclusive).
            if isfield(prop, 'pumpBasals')
                for n = ((0:this.simulationStepSize:(24 * 60)) / this.simulationStepSize) + 1
                    idx = find(prop.pumpBasals.time <= (n - 1)*this.simulationStepSize, 1, 'last');
                    if ~isempty(idx)
                        this.init.Basals(n) = prop.pumpBasals.value(idx);
                    else
                        this.init.Basals(n) = prop.pumpBasals.value(end);
                    end
                end
            elseif isfield(this.Patient, 'TDB') % Check for TDB.
                this.init.Basals = this.init.TDB * ones(ceil(24*60/this.simulationStepSize), 1) / 24;
            else % Assume 45% of TDD.
                this.init.Basals = 0.45 * this.init.TDD * ones(ceil(24*60/this.simulationStepSize), 1) / 24;
            end
            
            % this.init.CarbsF holds the carbFactors values for the day,
            % from midnight to next day's midnight (exclusive).
            if isfield(prop, 'carbFactors')
                for n = ((0:this.simulationStepSize:(24 * 60)) / this.simulationStepSize) + 1
                    idx = find(prop.carbFactors.time <= (n - 1)*this.simulationStepSize, 1, 'last');
                    if ~isempty(idx)
                        this.init.CarbsF(n) = prop.carbFactors.value(idx);
                    else
                        this.init.CarbsF(n) = prop.carbFactors.value(end);
                    end
                end
            else % Assume fixed value.
                this.init.CarbsF = 12 * ones(ceil(24*60/this.simulationStepSize), 1); % g/U.
            end
            
            % Set up constants.
            this.param.GHypo = 4.5;
            this.param.GHyper = 10.0;
            this.param.GTarg = 6.5;
            if ~isnan(this.patient.getGlucoseMeasurement())
                this.param.Gs0 = this.patient.getGlucoseMeasurement();
            else
                this.param.Gs0 = 6.5;
            end
            this.param.Weight = this.init.TDD / 0.53;
            this.param.Vg = 0.15; % Distribution volume of glucose (L/kg).
            this.param.Vi = 0.2; % Distribution volume of insulin (L/kg).
            this.param.Taui = 70.0; % Time-to-peak of insulin absorption (min).
            this.param.Taum = 40.0; % Time-to-peak of carbohydrate absorption (min).
            this.param.Taus = 12.0; % Sensor delay (min).
            this.param.Bio = 0.5; % Bioavailability of carbohydrates (0-1).
            this.param.MCHO = 180.156; % Molar mass of glucose (g/mol).
            this.param.Km = 1e3 * this.param.Bio / (this.param.MCHO * this.param.Vg * this.param.Weight);
            % Initialize insulin sensitivity parameter from TDD and carbFactor.
            SiBolus = (this.param.Bio * this.param.Km * mean(this.init.CarbsF)) / (this.param.Vg); % mmol / (L U).
            SiBasal = 1960 * (10 / this.param.MCHO) / this.init.TDD;
            this.param.Si = 0.7 * SiBasal + 0.3 * SiBolus; % mmol / (L U).
            % Initialize EGP parameter.
            this.param.Ub0 = this.init.Basals(floor(mod(this.simulationStartTime, 24*60)/this.simulationStepSize)+1);
            this.param.EGP = this.param.Si * this.param.Ub0 / 60; % Endogenous glucose production (mmol / (L min)).
            
            % Construct discrete state space representation matrices in continuous form.
            [Ac, Bc] = this.getTransitionMat(...
                [this.param.Si; ...
                this.param.Taui; ...
                this.param.Taum]);
            
            % Discretize.
            model.A = expm(Ac*this.simulationStepSize);
            model.B = ((model.A - eye(size(Ac))) / (Ac)) * Bc;
            model.B(:, 2) = model.A * [0; 0; 0; 0; 1; 0; 0];
            model.B(:, 3) = model.A * [0; 0; 0; 0; 0; 0; 1];
            model.C = [1, 0, 0, 0, 0, 0, 0];
            model.D = 0;
            model.X0 = [ ...
                this.param.Gs0; ...
                this.param.Gs0; ...
                this.param.EGP; ...
                this.param.Ub0 * this.param.Taui / 60; ...
                this.param.Ub0 * this.param.Taui / 60; ...
                0; ...
                0];
            
            % Kalman.
            this.kalmanParam.Q = diag([ ...
                0.5, ...
                1.0, ...
                0.25 * this.param.EGP, ...
                1.0, ...
                0.1, ...
                10.0, ...
                5.0])^2;
            this.kalmanParam.R = (0.7)^2;
            this.kalmanParam.model = model;
            this.kalmanParam.Acontr = -eye(length(this.kalmanParam.Q));
            this.kalmanParam.bcontr = zeros(length(this.kalmanParam.Q), 1);
            
            % MPC.
            this.mpcParam.NStep = round(4.0*60/this.simulationStepSize); % Prediction horizon.
            this.mpcParam.MStep = round(2.5*60/this.simulationStepSize); % Control horizon.
            this.mpcParam.model = model;
            this.mpcParam.model.B = model.B(:, 1); % MPC model is only concerned about basal insulin.
            this.mpcParam.model.C = [0, 1, 0, 0, 0, 0, 0]; % MPC controls plasma glucose.
            
            % Initialize Y, U, X, P.
            this.YLast = [];
            this.ULast = [];
            this.XLast = model.X0;
            this.PLast = this.kalmanParam.Q;
            % Y, U, X, P are circular buffers.
            % See also https://en.wikipedia.org/wiki/Circular_buffer.
            this.Y = nan(size(this.kalmanParam.model.C, 1), this.historySize);
            this.U = nan(size(this.kalmanParam.model.B, 2), this.historySize);
            this.X = nan(size(this.kalmanParam.model.A, 1), this.historySize);
            this.P = nan(size(this.kalmanParam.model.A, 1), size(this.kalmanParam.model.A, 1), this.historySize);
            this.mpcParam.quadprogOpt = optimoptions('quadprog', ...
                'Algorithm', 'interior-point-convex', ...
                'Display', 'off');
            
            this.counter = 1;
        end
        
        function [Gy, Gu, UbMin, UbMax] = getMPCGains(this, Ub)
            this.param.GTarg = 6.5;
            
            % Set limits.
            UbMin = -Ub;
            UbMax = min(4.0*max(Ub, mean(this.init.Basals)), 7.0-Ub);
            
            UNorm = max(min(Ub, 1.2*mean(this.init.Basals)), 0.6*mean(this.init.Basals));
            YNorm = this.param.GTarg * ones(1, this.mpcParam.NStep);
            
            % The gain is a linear function of IOB
            UGain = max(this.getIOB/(0.05 * this.init.TDD), 1);
            
            % Tuning parameters
            YGain = this.mpcParam.factor;
            
            Gy = YGain ./ (YNorm.^2);
            Gy(end) = 2 * Gy(end);
            Gu = UGain ./ (UNorm.^2);
            
            this.mpcParam.Gy = Gy;
            this.mpcParam.Gu = Gu;
        end
        
        function [H, f] = getMPCMatrices(this, X, U, Gy, Gu)
            n = size(this.mpcParam.model.A, 1);
            m = size(this.mpcParam.model.B, 2);
            
            this.mpcParam.AA = zeros(n*this.mpcParam.NStep, n);
            this.mpcParam.BB = zeros(n*this.mpcParam.NStep, m*this.mpcParam.MStep);
            
            PP = eye(n);
            for k = 1:this.mpcParam.NStep
                if k > 1
                    this.mpcParam.BB((k - 1)*n+1:(k)*n, m+1:end) = this.mpcParam.BB((k - 2)*n+1:(k - 1)*n, 1:(this.mpcParam.MStep - 1)*m);
                end
                this.mpcParam.BB((k - 1)*n+1:(k)*n, 1:m) = PP * this.mpcParam.model.B;
                PP = PP * this.mpcParam.model.A;
                this.mpcParam.AA((k - 1)*n+1:(k)*n, :) = PP;
            end
            this.mpcParam.CC = kron(eye(this.mpcParam.NStep, this.mpcParam.NStep), this.mpcParam.model.C);
            
            Gyy = diag(Gy);
            Guu = diag(Gu);
            
            H = this.mpcParam.BB' * this.mpcParam.CC' * Gyy * this.mpcParam.CC * this.mpcParam.BB + Guu;
            H = (H' + H) / 2;
            f = this.mpcParam.BB' * this.mpcParam.CC' * Gyy * ...
                (this.mpcParam.CC * this.mpcParam.AA * X + ...
                this.mpcParam.CC * this.mpcParam.BB * U - ...
                this.param.GTarg * ones(this.mpcParam.NStep, 1));
            
            this.mpcParam.H = H;
            this.mpcParam.f = f;
        end
        
        function [tt, YY, YY0] = getGlucosePredictions(this)
            tt = this.currentTime + ...
                (this.simulationStepSize:this.simulationStepSize:this.mpcParam.NStep * this.simulationStepSize);
            tt = tt(:);
            
            Ub = this.init.Basals(floor(mod( ...
                this.currentTime:this.simulationStepSize:this.currentTime+(this.mpcParam.MStep - 1)*this.simulationStepSize, ...
                24*60)/this.simulationStepSize)+1);
            Ub = Ub(:);
            
            if ~isempty(this.UULast)
                XX = this.mpcParam.AA * (this.XLast + this.kalmanParam.model.B * [0; this.ULast(2); this.ULast(3)]) + this.mpcParam.BB * (Ub + this.UULast);
                XX0 = this.mpcParam.AA * (this.XLast + this.kalmanParam.model.B * [0; this.ULast(2); this.ULast(3)]) + this.mpcParam.BB * Ub;
            else
                XX = this.mpcParam.AA * this.XLast + this.mpcParam.BB * Ub;
                XX0 = this.mpcParam.AA * this.XLast + this.mpcParam.BB * Ub;
            end
            YY = this.mpcParam.CC * XX;
            YY0 = this.mpcParam.CC * XX0;
        end
        
        function Xk_k = getStateEstimate(this)
            % Implements a Kalman filter's predict and update equations.
            % For more details, see https://en.wikipedia.org/wiki/Kalman_filter#Details.
            
            if this.counter == 1
                Xk_k = this.XLast;
                Pk_k = this.PLast;
            else
                Xk1_k1 = this.XLast;
                Pk1_k1 = this.PLast;
                Yk = this.YLast;
                Uk = this.ULast;
                
                Xk_k1 = this.kalmanParam.model.A * Xk1_k1 + this.kalmanParam.model.B * Uk;
                Pk_k1 = this.kalmanParam.model.A * Pk1_k1 * this.kalmanParam.model.A' + this.kalmanParam.Q;
                
                Sk = this.kalmanParam.model.C * Pk_k1 * this.kalmanParam.model.C' + this.kalmanParam.R;
                
                if ~isnan(Yk) % Missing data.
                    Kk = Pk_k1 * (this.kalmanParam.model.C' / Sk);
                    
                    Xk_k = Xk_k1 + Kk * (Yk - this.kalmanParam.model.C * Xk_k1);
                    Pk_k = (eye(size(this.kalmanParam.model.A, 1)) - Kk * this.kalmanParam.model.C) * Pk_k1;
                else
                    Xk_k = Xk_k1;
                    Pk_k = Pk_k1;
                end
                
                % Constrain Kalman estimate.
                if any(this.kalmanParam.Acontr*Xk_k > this.kalmanParam.bcontr+1e-4)
                    % Project on constraint space.
                    Xopt = Xk_k - Pk_k * this.kalmanParam.Acontr' * ...
                        ((this.kalmanParam.Acontr * Pk_k * this.kalmanParam.Acontr') \ ...
                        ((this.kalmanParam.Acontr * Xk_k - this.kalmanParam.bcontr) .* ...
                        (this.kalmanParam.Acontr * Xk_k > this.kalmanParam.bcontr + 1e-4)));
                    
                    % Update covariance and state.
                    Pk_k = Pk_k + (Xk_k - Xopt) * (Xk_k - Xopt)';
                    Xk_k = Xopt;
                end
            end
            
            this.XLast = Xk_k;
            this.X(:, 1:end-1) = this.X(:, 2:end);
            this.X(:, end) = this.XLast;
            
            this.PLast = Pk_k;
            this.P(:, :, 1:end-1) = this.P(:, :, 2:end);
            this.P(:, :, end) = this.PLast;
        end
        
        function [Ac, Bc] = getTransitionMat(this, p)
            Ac = [ ...
                -1 / this.param.Taus, 1 / this.param.Taus, 0, 0, 0, 0, 0; ...
                0, -1e-8, 1, -p(1) / p(2), 0, this.param.Km / p(3), 0; ...
                0, 0, -1e-8, 0, 0, 0, 0; ...
                0, 0, 0, -1 / p(2), 1 / p(2), 0, 0; ...
                0, 0, 0, 0, -1 / p(2), 0, 0; ...
                0, 0, 0, 0, 0, -1 / p(3), 1 / p(3); ...
                0, 0, 0, 0, 0, 0, -1 / p(3)];
            
            Bc = [ ...
                0; ...
                0; ...
                0; ...
                0; ...
                1 / 60; ...
                0; ...
                0];
        end
    end
    
end
