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
        eGluMeas = 9;
    end
    
    properties(GetAccess = public, SetAccess = protected)
        opt; % Options configured by the user.
        param; % Parameters configured by the specific patient model (patient0, patient1, ...).
        
        state;
        stateHistory;
        
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
                lastOptions.sensorNoise = false;
                lastOptions.intraVariability = false;
                lastOptions.mealVariability = false;
                lastOptions.randomInitialConditions = true;
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
            
            prompt(end+1, :) = {'Add sensor noise.', 'sensorNoise', []};
            formats(end+1, 1).type = 'check';
            
            prompt(end+1, :) = {'Random initial glucose value.', 'randomInitialConditions', []};
            formats(end+1, 1).type = 'check';
            
            prompt(end+1, :) = {'Add intra-patient variability.', 'intraVariability', []};
            formats(end+1, 1).type = 'check';
            
            prompt(end+1, :) = {'Add meal absorption variability.', 'mealVariability', []};
            formats(end+1, 1).type = 'check';
            
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
            this.opt.sensorNoise = false;
            this.opt.intraVariability = false;
            this.opt.mealVariability = false;
            this.opt.randomInitialConditions = true;
            this.opt.useTreatments = true;
            this.opt.randomPumpParam = false;
            this.opt.RNGSeed = -1;
            
            if exist('options', 'var')
                f = fields(this.opt);
                for i = 1:numel(f)
                    if isfield(options, f{i})
                        this.opt.(f{i}) = options.(f{i});
                    end
                end
            end
            
            if this.opt.RNGSeed > 0
                rng(this.opt.RNGSeed);
            end
            
            this.name = this.opt.name;
            eval(['this.', options.patient{1}]);
            
            % generate pump parameter error if needed
            if this.opt.randomPumpParam
                this.pumpParamError.basal = 0.5 * 2 * (rand(1) - 0.5);
                this.pumpParamError.bolus = 0.5 * 2 * (rand(1) - 0.5);
            end
            
            % Initialize state.
            this.state = this.getInitialState();
            this.stateHistory = nan(length(this.state), this.stateHistorySize);
            this.stateHistory(:, end) = this.state;
            
            % Initialize sensor model.
            this.CGM.lambda = 15.96; % Johnson parameter of recalibrated and synchronized sensor error.
            this.CGM.epsilon = -5.471; % Johnson parameter of recalibrated and synchronized sensor error.
            this.CGM.delta = 1.6898; % Johnson parameter of recalibrated and synchronized sensor error.
            this.CGM.gamma = -0.5444; % Johnson parameter of recalibrated and synchronized sensor error.
            this.CGM.error = 0;
            
            % Initialize meals.
            this.meals.added = 0;
            this.meals.index = 0;
            
            % Initialize glucagon boluses.
            this.glucagon.added = 0;
            this.glucagon.index = 0;
            
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
        end
        
        function prop = getProperties(this)
            prop = this.param;
            
            if this.opt.randomPumpParam
                prop.TDD = (1 + this.pumpParamError.basal) * prop.TDD;
                prop.pumpBasals.value = round(2*(1 + this.pumpParamError.basal).*prop.pumpBasals.value, 1) / 2;
                prop.carbFactors.value = round(2*(1 + this.pumpParamError.bolus).*prop.carbFactors.value) / 2;
            end
        end
        
        function glucose = getGlucoseMeasurement(this)
            sensorNoise = 0;
            if this.opt.sensorNoise > 0
                this.CGM.error = 0.7 * this.CGM.error + 0.3 * this.opt.sensorNoise * randn(1);
                sensorNoise = (10 / this.param.MCHO) * (this.CGM.epsilon + ...
                    this.CGM.lambda * sinh((this.CGM.error - this.CGM.gamma)/this.CGM.delta));
            end
            glucose = this.state(this.eGluMeas) + sensorNoise;
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
                    this.variability.EGP0.phase = 4 * 60 * rand(1);
                    this.variability.F01.phase = 4 * 60 * rand(1);
                    this.variability.k12.phase = 4 * 60 * rand(1);
                    this.variability.ka1.phase = 4 * 60 * rand(1);
                    this.variability.ka2.phase = 4 * 60 * rand(1);
                    this.variability.ka3.phase = 4 * 60 * rand(1);
                    this.variability.St.phase = 4 * 60 * rand(1);
                    this.variability.Sd.phase = 4 * 60 * rand(1);
                    this.variability.Se.phase = 4 * 60 * rand(1);
                    this.variability.ka.phase = 4 * 60 * rand(1);
                    this.variability.ke.phase = 4 * 60 * rand(1);
                    
                    this.variability.EGP0.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.F01.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.k12.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ka1.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ka2.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ka3.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.St.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.Sd.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.Se.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ka.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                    this.variability.ke.period = 4 * 60 + 2 * 60 * (rand(1) - 0.5);
                end
                
                this.firstIteration = false;
            end
            
            % Add treatment.
            hypoThreshold = 3.9; % mmol/L.
            if this.opt.useTreatments ...
                    && startTime - this.lastTreatmentTime > 40 ...
                    && max(this.stateHistory(this.eGluMeas, end-2:end)) < hypoThreshold
                this.addTreatment(startTime);
            end
            
            % Apply intra-variability.
            if this.opt.intraVariability
                this.applyIntraVariability(startTime);
            end
            
            % Add meal.
            meal = this.mealPlan.getMeal(startTime);
            if meal.value ~= 0
                if ~this.meals.added
                    this.meals.index = this.meals.index + 1;
                    this.meals.value(this.meals.index) = meal.value;
                    this.meals.time(this.meals.index) = startTime;
                    this.meals.TauM(this.meals.index) = max(min(this.param.TauM.*(1 + this.opt.mealVariability .* randn(1)), 75), 25);
                    this.meals.Bio(this.meals.index) = this.param.Bio;
                    this.meals.added = 1;
                    this.lastTreatmentTime = startTime;
                end
            else
                this.meals.added = 0;
            end
            
            % Add insulin bolus.
            this.state(this.eInsSub1) = this.state(this.eInsSub1) + Ubolus;
            
            % Add glucagon bolus.
            if Ugbolus ~= 0
                if ~this.glucagon.added
                    this.glucagon.index = this.glucagon.index + 1;
                    this.glucagon.value(this.glucagon.index) = Ugbolus;
                    this.glucagon.time(this.glucagon.index) = startTime;
                    this.glucagon.added = 1;
                end
            else
                this.glucagon.added = 0;
            end
            
            % Simulate.
            [~, Y] = ode15s(@(t, y) this.model(t, y, Ubasal), ...
                [startTime, endTime], ...
                this.state);
            this.state = Y(end, :)';
            
            % Save states in history.
            this.stateHistory(:, 1:end-1) = this.stateHistory(:, 2:end);
            this.stateHistory(:, end) = this.state;
        end
        
        function meal = getMeal(this, time)
            meal = this.getMeal@VirtualPatient(time);
            
            % This patient can forget to announce meals to the controller!
            if isfield(meal, 'announced')
                meal.value = meal.announced .* meal.value;
            end
        end
    end
    
    methods(Access = private)
        function applyIntraVariability(this, t)
            alp = 0.2; % Filter parameter changes.
            
            this.variability.EGP0.val = (1 - alp) * this.variability.EGP0.val + alp * this.param.EGP0 * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.EGP0.phase)/(this.variability.EGP0.period)));
            this.variability.F01.val = (1 - alp) * this.variability.F01.val + alp * this.param.F01 * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.F01.phase)/(this.variability.F01.period)));
            this.variability.k12.val = (1 - alp) * this.variability.k12.val + alp * this.param.k12 * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.k12.phase)/(this.variability.ka1.period)));
            this.variability.ka1.val = (1 - alp) * this.variability.ka1.val + alp * this.param.ka1 * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.ka1.phase)/(this.variability.F01.period)));
            this.variability.ka2.val = (1 - alp) * this.variability.ka2.val + alp * this.param.ka2 * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.ka2.phase)/(this.variability.ka2.period)));
            this.variability.ka3.val = (1 - alp) * this.variability.ka3.val + alp * this.param.ka3 * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.ka3.phase)/(this.variability.ka3.period)));
            this.variability.St.val = (1 - alp) * this.variability.St.val + alp * this.param.St * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.St.phase)/(this.variability.St.period)));
            this.variability.Sd.val = (1 - alp) * this.variability.Sd.val + alp * this.param.Sd * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.Sd.phase)/(this.variability.Sd.period)));
            this.variability.Se.val = (1 - alp) * this.variability.Se.val + alp * this.param.Se * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.Se.phase)/(this.variability.Se.period)));
            this.variability.ka.val = (1 - alp) * this.variability.ka.val + alp * this.param.ka * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.ka.phase)/(this.variability.ka.period)));
            this.variability.ke.val = (1 - alp) * this.variability.ke.val + alp * this.param.ke * (1 + this.opt.intraVariability * 0.25 * sin(2*pi*(t + this.variability.ke.phase)/(this.variability.ke.period)));
        end
        
        function initialState = getInitialState(this)
            % Glucose measurement (mmol/L).
            Gs0 = 7.0;
            if this.opt.randomInitialConditions > 0
                Gs0 = normrnd(7, 3.5);
                while Gs0 < 5 || Gs0 > 9
                    Gs0 = normrnd(7, 3.5);
                end
            end
            
            initialState(this.eGluMeas) = Gs0;
            
            % Plasma glucose (umol/kg).
            Q10 = Gs0 * this.param.Vg;
            initialState(this.eGluPlas) = Q10;
            
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
            
            % On-board bolus.
            Qb = 0;
            if this.opt.randomInitialConditions > 0
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
            
            % Basal insulin.
            Ub = 60 * Ip0 * this.param.ke / (1e6 / (this.param.Vi * this.param.w));
            
            initialState(this.eInsSub1) = Ub / 60 / this.param.ka;
            initialState(this.eInsSub2) = initialState(this.eInsSub1);
            
            % Set patient basal insulin rates.
            this.param.pumpBasals.value = round(2*Ub, 1) / 2;
            this.param.pumpBasals.time = 0;
            
            this.param.TDD = round(Ub*24/0.47, 2);
            
            % Compute an approximation of patient carb factor.
            this.param.carbFactors.value = round(2*(this.param.MCHO * (0.4 * this.param.St + 0.6 * this.param.Sd) * Gs0 * this.param.Vg)/(this.param.ke * this.param.Vi)) / 2; % g/U.
            this.param.carbFactors.time = 0;
            
            initialState = initialState(:);
        end
        
        function dydt = model(this, t, y, u)
            dydt = zeros(size(y));
            
            % Subcutaneous insulin absorption subsystem (U).
            dydt(this.eInsSub1) = u / 60 - y(this.eInsSub1) * this.variability.ka.val;
            dydt(this.eInsSub2) = y(this.eInsSub1) * this.variability.ka.val - y(this.eInsSub2) * this.variability.ka.val;
            
            % Subcutaneous glucagon boluses absorption subsystem.
            GluPlas = 0; % pg/mL.
            if this.glucagon.index > 0
                for m = 1:this.glucagon.index
                    GluPlas = GluPlas + ...
                        (1e6 / (this.param.w * this.param.MCRGlu)) * this.glucagon.value(m) * ...
                        (t - this.glucagon.time(m)) * exp(-(t - this.glucagon.time(m))/this.param.TauGlu) / this.param.TauGlu^2;
                end
            end
            
            % Plasma insulin kinetics subsystem (mU/L).
            dydt(this.eInsPlas) = 1e6 * y(this.eInsSub2) * this.variability.ka.val / (this.param.Vi * this.param.w) - y(this.eInsPlas) * this.variability.ke.val;
            
            % Plasma insulin action subsystem ((1/min) / (1/min) / no-units).
            dydt(this.eInsActT) = -this.variability.ka1.val * y(this.eInsActT) + this.variability.ka1.val * this.variability.St.val * y(this.eInsPlas);
            dydt(this.eInsActD) = -this.variability.ka2.val * y(this.eInsActD) + this.variability.ka2.val * this.variability.Sd.val * y(this.eInsPlas);
            dydt(this.eInsActE) = -this.variability.ka3.val * y(this.eInsActE) + this.variability.ka3.val * this.variability.Se.val * y(this.eInsPlas);
            
            % Gut absorption subsystem (umol/kg/min).
            Um = 0;
            if this.meals.index > 0
                for m = 1:this.meals.index
                    Um = Um + ...
                        (1e6 / (this.param.w * this.param.MCHO)) * this.meals.Bio(m) * this.meals.value(m) * ...
                        (t - this.meals.time(m)) * exp(-(t - this.meals.time(m))/this.meals.TauM(m)) / this.meals.TauM(m)^2;
                end
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
            dydt(this.eGluMeas) = (y(this.eGluPlas) / this.param.Vg - y(this.eGluMeas)) / this.param.TauS;
        end
        
        function addTreatment(this, time)
            % Append meal info to mealPlan.
            this.mealPlan.addTreatment(time, 15);
            
            % Consume the meal.
            this.meals.index = this.meals.index + 1;
            this.meals.value(this.meals.index) = 15;
            this.meals.time(this.meals.index) = time;
            this.meals.TauM(this.meals.index) = 20;
            this.meals.Bio(this.meals.index) = this.param.Bio;
            this.meals.added = 1;
            this.lastTreatmentTime = time;
        end
    end
    
end
