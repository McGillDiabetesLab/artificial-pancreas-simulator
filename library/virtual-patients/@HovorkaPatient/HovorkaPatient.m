classdef HovorkaPatient < VirtualPatient
    %HOVORKAPATIENT  Virtual patient model.
    %   This model is based on a published model by Dr. Hovorka Romain.
    %   They used this model for their simulation environment in
    %   Wilinska, M. E., et al. (2010).
    %   "Simulation environment to evaluate closed-loop insulin delivery
    %   systems in type 1 diabetes." J Diabetes Sci Technol 4(1): 132-144.
    %
    %   If needed one can add his own custom Hovorka patient by making a
    %   file similar to patient1.m.
    %
    %   See also /VIRTUALPATIENT.
    
    properties(GetAccess = public, SetAccess = immutable)
        stateHistorySize = 1000;
        
        % State enumeration.
        eInsSub1 = 1;
        eInsSub2 = 2;
        eInsPlas = 3;
        eInsActT = 4;
        eInsActD = 5;
        eInsActE = 6;
        eGluPlas = 7;
        eGluComp = 8;
        eGluInte = 9;
        eGluMeas = 10;
    end
    
    properties(GetAccess = public, SetAccess = protected)
        opt; % Options configured by the user.
        param; % Parameters configured by the specific patient model (patient0, patient1, ...).
        
        state;
        stateHistory;
        
        stateScale = [];
        
        meals;
        glucagon;
        CGM; % Recalibrated and synchronized sensor error.
        variability; % Intra-patient variability.
        pumpParamError;
        
        lastTreatmentTime = 0;
        firstIteration = true;
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            if ~exist('lastOptions', 'var')
                lastOptions = struct();
                lastOptions.name = className;
                lastOptions.patient = {'patient1'};
                lastOptions.sensorNoiseType = {'none'};
                lastOptions.sensorNoiseValue = 0.0;
                lastOptions.intraVariability = 0.0;
                lastOptions.mealVariability = 0.0;
                lastOptions.initialGlucose = -1;
                lastOptions.basalGlucose = 5.5;
                lastOptions.useTreatments = true;
            end
            
            dlgTitle = 'Configure Hovorka Patient';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Patient name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200; % Automatically assign the height.
            
            prompt(end+1, :) = {'Patient model:', 'patient', evalc(['help ', className, '.', lastOptions.patient{1}])};
            formats(end+1, 1).type = 'list';
            formats(end, 1).style = 'listbox';
            formats(end, 1).format = 'text'; % Answer will give value shown in items, disable to get integer.
            formats(end, 1).items = {};
            m = methods(className);
            for i = 1:numel(m)
                startIndex = regexp(m{i}, '^patient[0-9]+$');
                if startIndex == 1
                    formats(end, 1).items{end+1} = m{i};
                end
            end
            formats(end, 1).limits = [1, 1]; % One-select.
            formats(end, 1).size = [75, 100];
            formats(end, 1).callback = @(hObj, ~, handles, k) ...
                set(handles(k, 3), 'String', evalc(['help ', className, '.', hObj.String{hObj.Value}]));
            
            prompt(end+1, :) = {'Type of glucose sensor noise', 'sensorNoiseType', []};
            formats(end+1, 1).type = 'list';
            formats(end, 1).format = 'text';
            formats(end, 1).items = {'none', 'white', 'AR(1)', 'johnson'};
            formats(end, 1).limits = [1, 1]; % One-select
            formats(end, 1).size = 100;
            function setSensorNoiseCV(~, ~, handles, k)
                if get(handles(k, 1), 'Value') == 1 || get(handles(k, 1), 'Value') == 4
                    set(handles(k+1, 1), 'Enable', 'off')
                else
                    set(handles(k+1, 1), 'Enable', 'on')
                end
            end
            formats(end, 1).callback = @setSensorNoiseCV;
            
            prompt(end+1, :) = {'Glucose sensor noise', 'sensorNoiseValue', []};
            formats(end, 2).type = 'edit';
            formats(end, 2).format = 'float';
            if (strcmp(lastOptions.sensorNoiseType, 'none') || strcmp(lastOptions.sensorNoiseType, 'johnson'))
                formats(end, 2).enable = 'off';
            else
                formats(end, 2).enable = 'on';
            end
            formats(end, 2).size = 100;
            
            prompt(end+1, :) = {'Initial glucose value (-1 for random value between [5-11] mmol/L).', 'initialGlucose', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 200;
            formats(end, 1).span = [1, 2];
            
            prompt(end+1, :) = {'Basal glucose value (-1 for random value between [5-11] mmol/L).', 'basalGlucose', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 200;
            formats(end, 1).span = [1, 2];
            
            prompt(end+1, :) = {'CV of intra-patient variability', 'intraVariability', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 200;
            formats(end, 1).span = [1, 2];
            
            prompt(end+1, :) = {'CV of meal absorption variability', 'mealVariability', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 200;
            formats(end, 1).span = [1, 2];
            
            prompt(end+1, :) = {'Automatically consume carbs when hypo.', 'useTreatments', []};
            formats(end+1, 1).type = 'check';
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, lastOptions);
            
            options = [];
            if ~cancelled
                options = answer;
            end
        end
    end
    
    methods
        function this = HovorkaPatient(mealPlan, exercisePlan, options)
            this@VirtualPatient(mealPlan, exercisePlan);
            
            % Parse options.
            this.opt = struct();
            this.opt.name = this.name;
            this.opt.patient = {'patient1'};
            this.opt.sensorNoiseType = 'none';
            this.opt.sensorNoiseValue = 0;
            this.opt.intraVariability = 0.0;
            this.opt.mealVariability = 0.0;
            this.opt.initialGlucose = -1;
            this.opt.basalGlucose = 5.5;
            this.opt.useTreatments = true;
            this.opt.wrongPumpParam = false;
            this.opt.pumpParamError = struct();
            this.opt.RNGSeed = -1;
            
            if exist('options', 'var')
                f = fields(this.opt);
                for i = 1:numel(f)
                    if isfield(options, f{i})
                        this.opt.(f{i}) = options.(f{i});
                    end
                end
            end
            
            % Set patient name
            this.name = this.opt.name;
            
            % Generate patient parameter.
            if this.opt.RNGSeed > 0
                rng(this.opt.RNGSeed);
            end
            eval(['this.', this.opt.patient{1}]);
            
            % Generate pump parameter error.
            if this.opt.wrongPumpParam
                if ~isempty(fieldnames(this.opt.pumpParamError))
                    this.pumpParamError.basal = this.opt.pumpParamError.basal;
                    this.pumpParamError.bolus = this.opt.pumpParamError.bolus;
                else
                    this.pumpParamError.basal = 0.5 * 2 * (rand(1) - 0.5);
                    this.pumpParamError.bolus = 0.5 * 2 * (rand(1) - 0.5);
                end
            end
            
            % Initialize state.
            this.state = this.getInitialState();
            this.stateHistory = nan(length(this.state), this.stateHistorySize);
            this.stateHistory(:, end) = this.state;
            
            % Set patient basal insulin rates.
            this.param.pumpBasals.value = round(this.param.Ub, 2);
            this.param.pumpBasals.time = 0;
            
            % Compute an approximation of patient carb factor.
            meanCarbF = (this.param.MCHO * (0.4 * max(this.param.St, 16e-4) + 0.6 * min(max(this.param.Sd, 3e-4), 7e-4)) * 5.0 * this.param.Vg) / (this.param.ke * this.param.Vi); % g/U.
            this.param.carbFactors.value = min(max(round(2*[meanCarbF, meanCarbF, meanCarbF])/2, 2), 25);
            this.param.carbFactors.time = [7; 12; 17] * 60;
            
            this.param.TDD = min(max(round(this.param.Ub*24+200/meanCarbF, 2), 10), 110);
            
            % Initialize sensor model.
            this.CGM.lambda = 15.96; % Johnson parameter of recalibrated and synchronized sensor error.
            this.CGM.epsilon = -5.471; % Johnson parameter of recalibrated and synchronized sensor error.
            this.CGM.delta = 1.6898; % Johnson parameter of recalibrated and synchronized sensor error.
            this.CGM.gamma = -0.5444; % Johnson parameter of recalibrated and synchronized sensor error.
            this.CGM.error = 0;
            
            % Initialize meals.
            this.meals = struct([]);
            
            % Initialize glucagon boluses.
            this.glucagon = struct([]);
            
            % Initialize intra-variability parameters.
            this.variability.EGP0.val = this.param.EGP0;
            this.variability.F01.val = this.param.F01;
            this.variability.k12.val = this.param.k12;
            this.variability.ka1.val = this.param.ka1;
            this.variability.ka2.val = this.param.ka2;
            this.variability.ka3.val = this.param.ka3;
            this.variability.St.val = this.param.St;
            this.variability.Sd.val = this.param.Sd;
            this.variability.Se.val = this.param.Se;
            this.variability.ka.val = this.param.ka;
            this.variability.ke.val = this.param.ke;
            
            % Set scaling for states
            this.stateScale = [; ...
                1.0; ... % U
                1.0; ... % U
                1e-6 * 60 * this.param.ke * (this.param.Vi * this.param.w); ... % mU / L -> U
                1.0; ... % 1/min
                1.0; ... % 1/min
                1.0; ... % no-units
                1 / this.param.Vg; ... % umol/kg -> mmol/L
                1 / this.param.Vg; ... % umol/kg -> mmol/L
                1.0; ... % mmol/L
                1.0; ... % mmol/L
                ];
        end
        
        function prop = getProperties(this)
            prop = this.param;
            
            if this.opt.wrongPumpParam
                prop.TDD = (1 + 0.47 * this.pumpParamError.basal) * prop.TDD;
                prop.pumpBasals.value = round((1 + this.pumpParamError.basal).*prop.pumpBasals.value, 2);
                prop.carbFactors.value = round(2*(1 + this.pumpParamError.bolus).*prop.carbFactors.value) / 2;
            end
        end
        
        function glucose = getGlucoseMeasurement(this)
            glucose = this.state(this.eGluMeas);
        end
        
        function updateState(this, startTime, endTime, infusions)
            % Reset random number generator
            if this.opt.RNGSeed > 0
                rng(mod(startTime*this.opt.RNGSeed, 999983));
            end
            
            % Get infusions.
            Ubasal = max(infusions.basalInsulin, 0);
            Ubolus = max(infusions.bolusInsulin, 0);
            Ugbolus = 0;
            if isfield(infusions, 'bolusGlucagon')
                Ugbolus = max(infusions.bolusGlucagon, 0);
            end
            
            if rem(startTime, 24*60) == 0 || this.firstIteration
                % Add intra-variability.
                if this.opt.intraVariability > 0
                    % Reset intra-patient variability.
                    this.variability.EGP0.phase = 2 * 60 * rand(1);
                    this.variability.F01.phase = 2 * 60 * rand(1);
                    this.variability.k12.phase = 2 * 60 * rand(1);
                    this.variability.ka1.phase = 2 * 60 * rand(1);
                    this.variability.ka2.phase = 2 * 60 * rand(1);
                    this.variability.ka3.phase = 2 * 60 * rand(1);
                    this.variability.St.phase = 2 * 60 * rand(1);
                    this.variability.Sd.phase = 2 * 60 * rand(1);
                    this.variability.Se.phase = 2 * 60 * rand(1);
                    this.variability.ka.phase = 2 * 60 * rand(1);
                    this.variability.ke.phase = 2 * 60 * rand(1);
                    
                    this.variability.EGP0.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.F01.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.k12.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ka1.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ka2.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ka3.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.St.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.Sd.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.Se.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ka.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ke.period = 3 * 60 + 2 * 60 * (rand(1) - 0.5);
                end
            end
            
            % Apply intra-variability.
            if this.opt.intraVariability > 0
                this.applyIntraVariability(startTime);
            end
            
            % Add meal.
            meal = this.mealPlan.getMeal(startTime);
            if meal.value ~= 0
                this.meals(end+1).value = meal.value;
                this.meals(end).time = startTime;
                if meal.glycemicLoad < 10
                    this.meals(end).gutAbsorptionModel = @this.gut2CompModel;
                    this.meals(end).TauM = max(min(this.param.TauM.*(1 + this.opt.mealVariability * randn(1)), 75), 25);
                else
                    this.meals(end).gutAbsorptionModel = @this.gut4CompDelayedModel;
                    this.meals(end).TauM1 = max(min(this.param.TauM.*(1 + this.opt.mealVariability * randn(1)), 75), 25);
                    this.meals(end).TauM2 = max(min(this.param.TauM*1.5*(1 + this.opt.mealVariability * randn(1)), 75), 25);
                    if this.opt.mealVariability > 0.0
                        this.meals(end).Delay = 10 + 20 * rand(1);
                        this.meals(end).Prop = 0.5 + 0.4 * rand(1);
                    else
                        this.meals(end).Delay = 10;
                        this.meals(end).Prop = 0.7;
                    end
                end
                if this.opt.mealVariability > 0.2
                    this.meals(end).Bio = this.param.Bio * (0.85 + 0.3 * rand(1));
                else
                    this.meals(end).Bio = this.param.Bio;
                end
                this.lastTreatmentTime = startTime;
            end
            
            % Add insulin bolus.
            this.state(this.eInsSub1) = this.state(this.eInsSub1) + Ubolus;
            
            % Add glucagon bolus.
            if Ugbolus ~= 0
                this.glucagon(end+1).value = Ugbolus;
                this.glucagon(end).time = startTime;
            end
            
            % Simulate.
            [~, Y] = ode15s(@(t, y) this.model(t, y, Ubasal), ...
                [startTime, endTime], ...
                this.state);
            this.state = Y(end, :)';
            
            % update sensor noise
            if this.firstIteration
                this.CGM.error = 0;
            else
                switch lower(char(this.opt.sensorNoiseType))
                    case 'johnson'
                        sensor_noise = 0.7 * (this.CGM.error + randn(1));
                        this.CGM.error = (10 / this.param.MCHO) * (this.CGM.epsilon + ...
                            this.CGM.lambda * sinh((sensor_noise - this.CGM.gamma)/this.CGM.delta));
                    case {'ar(1)', 'colored'}
                        phi = 0.8;
                        this.CGM.error = phi * this.CGM.error + ...
                            sqrt(1-phi^2) * this.opt.sensorNoiseValue * randn(1);
                    case 'mult'
                        this.CGM.error = this.opt.sensorNoiseValue * this.state(this.eGluInte) * randn(1);
                    case {'white', 'add'}
                        this.CGM.error = this.opt.sensorNoiseValue * randn(1);
                    otherwise
                        this.CGM.error = 0;
                end
            end
            
            % add sensor noise
            this.state(this.eGluMeas) = this.state(this.eGluInte) + this.CGM.error;
            
            % Add treatment.
            if this.opt.useTreatments ...
                    && startTime - this.lastTreatmentTime > 35
                meals_ = this.mealPlan.getMeal(startTime:this.mealPlan.simulationStepSize:startTime+20);
                if sum(meals_.value) < 15 % if patient is not planning to eat more than 15 g
                    hypoThreshold = 3.0; % mmol/L.
                    prolongedHypoThreshold = 3.9; % mmol/L.
                    if all(this.stateHistory(this.eGluPlas, end-5:end)/this.param.Vg < prolongedHypoThreshold)
                        this.addTreatment(startTime, 30);
                    elseif this.state(this.eGluPlas) / this.param.Vg < hypoThreshold
                        this.addTreatment(startTime, 15);
                    end
                end
            end
            
            % Save states in history.
            this.stateHistory(:, 1:end-1) = this.stateHistory(:, 2:end);
            this.stateHistory(:, end) = this.state;
            
            if this.firstIteration
                this.firstIteration = false;
            end
        end
        
        function meal = getMeal(this, time)
            meal = this.getMeal@VirtualPatient(time);
            
            % This patient can forget to announce meals to the controller!
            if isfield(meal, 'announced')
                meal.value = meal.announced .* meal.value;
                meal.glycemicLoad = meal.announced .* meal.glycemicLoad;
            end
        end
        
        function initialState = getInitialState(this)
            
            initialState = nan(this.eGluMeas, 1);
            
            recomputeGs0 = true;
            iter = 0;
            
            while iter < 1e2 && recomputeGs0
                iter = iter + 1;
                
                % Basal Glucose (mmol/L).
                if this.opt.basalGlucose < 0
                    GBasal = normrnd(7, 3.5);
                    while GBasal < 5 || GBasal > 11
                        GBasal = normrnd(7, 3.5);
                    end
                else
                    GBasal = this.opt.basalGlucose;
                end
                
                % Plasma glucose (umol/kg).
                Q10 = GBasal * this.param.Vg;
                
                Fn = Q10 * (this.param.F01 / 0.85) / (Q10 + this.param.Vg);
                Fr = this.param.RCl * (Q10 - this.param.RTh * this.param.Vg) * (Q10 > this.param.RTh * this.param.Vg);
                Slin = roots([ ...
                    (-Q10 * this.param.St * this.param.Sd - this.param.EGP0 * this.param.Sd * this.param.Se), ...
                    (-this.param.k12 * this.param.EGP0 * this.param.Se + (this.param.EGP0 - Fr - Fn) * this.param.Sd), ...
                    this.param.k12 * (this.param.EGP0 - Fn - Fr), ...
                    ]);
                syms x positive
                S = vpasolve(-Fn ...
                    -Q10*this.param.St*x ...
                    +this.param.k12*(Q10 * this.param.St * x)/(this.param.k12 + this.param.Sd * x) ...
                    -Fr ...
                    +this.param.EGP0*exp(-this.param.Se*x) == 0, x, max(double(Slin)));
                
                % Insulin plasma (mU/L).
                if ~isempty(S) && isreal(double(S))
                    Ip0 = double(S);
                else
                    Ip0 = abs(S);
                    warning('Couldn''t solve for initial conditions!');
                end
                
                % Basal insulin.
                this.param.Ub = 60 * Ip0 * this.param.ke / (1e6 / (this.param.Vi * this.param.w));
                
                if this.opt.basalGlucose < 0
                    if this.param.Ub < 2.2 && this.param.Ub > 0.1
                        recomputeGs0 = false;
                    else
                        recomputeGs0 = true;
                    end
                else
                    recomputeGs0 = false;
                end
            end
            
            % Glucose measurement (mmol/L).
            if this.opt.initialGlucose < 0
                Gs0 = this.opt.basalGlucose * (1 + 0.7 * randn(1));
                while Gs0 < 5 || Gs0 > 14
                    Gs0 = this.opt.basalGlucose * (1 + 0.7 * randn(1));
                end
            else
                Gs0 = this.opt.initialGlucose;
            end
            
            initialState(this.eGluPlas) = Gs0 * this.param.Vg;
            initialState(this.eGluMeas) = Gs0;
            initialState(this.eGluInte) = Gs0;
            
            % On-board bolus.
            Qb = 0;
            if this.opt.initialGlucose < 0
                Qb = 2.5 * (rand(1) - 0.5);
                while 0.8 * Ip0 + Qb / (this.param.ke / (1e6 * this.param.ka / (this.param.Vi * this.param.w))) < 0
                    Qb = 2.5 * (rand(1) - 0.5);
                end
            end
            
            initialState(this.eInsPlas) = Ip0 + Qb / (this.param.ke / (1e6 * this.param.ka / (this.param.Vi * this.param.w)));
            
            % Insulin actions.
            initialState(this.eInsActT) = this.param.St * initialState(this.eInsPlas);
            initialState(this.eInsActD) = this.param.Sd * initialState(this.eInsPlas);
            initialState(this.eInsActE) = this.param.Se * initialState(this.eInsPlas);
            
            % Glucose plasma.
            Q20 = Q10 * initialState(this.eInsActT) / (initialState(this.eInsActD) + this.param.k12); % umol/kg.
            initialState(this.eGluComp) = Q20;
            
            % Subcutenous insulin
            initialState(this.eInsSub1) = this.param.Ub / 60 / this.param.ka;
            initialState(this.eInsSub2) = initialState(this.eInsSub1);
            
            initialState = initialState(:);
        end
    end
    
    methods(Access = private)
        function applyIntraVariability(this, t)
            alp = 0.3; % Filter parameter changes.
            
            this.variability.EGP0.val = (1 - alp) * this.variability.EGP0.val + alp * this.param.EGP0 * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.EGP0.phase)/(this.variability.EGP0.period)));
            this.variability.F01.val = (1 - alp) * this.variability.F01.val + alp * this.param.F01 * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.F01.phase)/(this.variability.F01.period)));
            this.variability.k12.val = (1 - alp) * this.variability.k12.val + alp * this.param.k12 * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.k12.phase)/(this.variability.ka1.period)));
            this.variability.ka1.val = (1 - alp) * this.variability.ka1.val + alp * this.param.ka1 * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.ka1.phase)/(this.variability.F01.period)));
            this.variability.ka2.val = (1 - alp) * this.variability.ka2.val + alp * this.param.ka2 * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.ka2.phase)/(this.variability.ka2.period)));
            this.variability.ka3.val = (1 - alp) * this.variability.ka3.val + alp * this.param.ka3 * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.ka3.phase)/(this.variability.ka3.period)));
            this.variability.St.val = (1 - alp) * this.variability.St.val + alp * this.param.St * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.St.phase)/(this.variability.St.period)));
            this.variability.Sd.val = (1 - alp) * this.variability.Sd.val + alp * this.param.Sd * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.Sd.phase)/(this.variability.Sd.period)));
            this.variability.Se.val = (1 - alp) * this.variability.Se.val + alp * this.param.Se * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.Se.phase)/(this.variability.Se.period)));
            this.variability.ka.val = (1 - alp) * this.variability.ka.val + alp * this.param.ka * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.ka.phase)/(this.variability.ka.period)));
            this.variability.ke.val = (1 - alp) * this.variability.ke.val + alp * this.param.ke * (1 + this.opt.intraVariability * sin(2*pi*(t + this.variability.ke.phase)/(this.variability.ke.period)));
        end
        
        function Um = gut4CompDelayedModel(this, t, meal)
            Qm1 = (t - meal.time) * exp(-(t - meal.time)/meal.TauM1) / meal.TauM1^2;
            if t > (meal.time + meal.Delay)
                Qm2 = (t - meal.time) * exp(-(t - meal.time - meal.Delay)/meal.TauM2) / meal.TauM2^2;
            else
                Qm2 = 0;
            end
            
            Um = (1e6 / (this.param.w * this.param.MCHO)) * meal.Bio * meal.value * (meal.Prop * Qm1 + (1 - meal.Prop) * Qm2);
        end
        
        function Um = gut2CompModel(this, t, meal)
            Um = (1e6 / (this.param.w * this.param.MCHO)) * meal.Bio * meal.value * ...
                (t - meal.time) * exp(-(t - meal.time)/meal.TauM) / meal.TauM^2;
        end
        
        function dydt = model(this, t, y, u)
            dydt = zeros(size(y));
            
            % Subcutaneous insulin absorption subsystem (U).
            dydt(this.eInsSub1) = u / 60 - y(this.eInsSub1) * this.variability.ka.val;
            dydt(this.eInsSub2) = y(this.eInsSub1) * this.variability.ka.val - y(this.eInsSub2) * this.variability.ka.val;
            
            % Subcutaneous glucagon boluses absorption subsystem.
            GluPlas = 0; % pg/mL.
            for g = 1:length(this.glucagon)
                GluPlas = GluPlas + ...
                    (1e6 / (this.param.w * this.param.MCRGlu)) * this.glucagon(g).value * ...
                    (t - this.glucagon(g).time) * exp(-(t - this.glucagon(g).time)/this.param.TauGlu) / this.param.TauGlu^2;
            end
            
            % Plasma insulin kinetics subsystem (mU/L).
            dydt(this.eInsPlas) = 1e6 * y(this.eInsSub2) * this.variability.ka.val / (this.param.Vi * this.param.w) - y(this.eInsPlas) * this.variability.ke.val;
            
            % Plasma insulin action subsystem ((1/min) / (1/min) / no-units).
            dydt(this.eInsActT) = -this.variability.ka1.val * y(this.eInsActT) + this.variability.ka1.val * this.variability.St.val * y(this.eInsPlas);
            dydt(this.eInsActD) = -this.variability.ka2.val * y(this.eInsActD) + this.variability.ka2.val * this.variability.Sd.val * y(this.eInsPlas);
            dydt(this.eInsActE) = -this.variability.ka3.val * y(this.eInsActE) + this.variability.ka3.val * this.variability.Se.val * y(this.eInsPlas);
            
            % Gut absorption subsystem (umol/kg/min).
            Um = 0;
            for m = 1:length(this.meals)
                Um = Um + this.meals(m).gutAbsorptionModel(t, this.meals(m));
            end
            
            % Glucose kinetics subsystem (umol/kg).
            dydt(this.eGluPlas) = -((this.variability.F01.val / 0.85) / (y(this.eGluPlas) + this.param.Vg) + y(this.eInsActT)) * y(this.eGluPlas) ...
                +this.variability.k12.val * y(this.eGluComp) ...
                -this.param.RCl * (y(this.eGluPlas) - this.param.RTh * this.param.Vg) * (y(this.eGluPlas) > this.param.RTh * this.param.Vg) ...
                +this.variability.EGP0.val * (exp(-y(this.eInsActE)) + exp(-1/(GluPlas * this.param.TGlu))) ...
                +Um;
            dydt(this.eGluComp) = y(this.eInsActT) * y(this.eGluPlas) ...
                -(this.variability.k12.val + y(this.eInsActD)) * y(this.eGluComp);
            
            % Glucose sensor (mmol/L).
            dydt(this.eGluInte) = (y(this.eGluPlas) / this.param.Vg - y(this.eGluInte)) / this.param.TauS;
        end
        
        function addTreatment(this, time, meal)
            % Append meal info to mealPlan.
            this.mealPlan.addTreatment(time, meal);
            
            % Consume the meal.
            this.meals(end+1).value = meal;
            this.meals(end).time = time;
            this.meals(end).gutAbsorptionModel = @this.gut2CompModel;
            this.meals(end).TauM = 20;
            this.meals(end).Bio = this.param.Bio;
            this.lastTreatmentTime = time;
        end
    end
    
end
