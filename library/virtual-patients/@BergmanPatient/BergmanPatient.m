classdef BergmanPatient < VirtualPatient
    %%BergmanPatient
    % This model is based on the Model 6 of Bergman paper
    %
    % R. N. Bergman et al., "Quantitative estimation of insulin
    % sensitivity," Am J Physiol, vol. 236, no. 6, pp. E667-77, Jun 1979.
    %
    
    
    properties (GetAccess = public, SetAccess = private)
        opt;
    end
    
    properties (GetAccess = public, SetAccess = immutable)
        stateHistorySize = 1000;
        
        
        % enumuraion
        eInsSub = 1;
        eInsPlas = 2;
        eInsAct = 3;
        eGluPlas = 4;
        eGluInte = 5;
        eGluMeas = 6;
    end
    
    properties (GetAccess = private, SetAccess = private)
        param; % Parameters configured by the specific patient model (patient0, patient1, ...).
        state; % a vector of n x 1
        stateHistory;
        meals;
        exercises;
        CGM;
        
        firstIteration = true;
    end
    
    methods
        function this = BergmanPatient(mealPlan, exercisePlan, options)
            this@VirtualPatient(mealPlan, exercisePlan);
            
            % Parse options.
            this.opt = struct();
            this.opt.name = this.name;
            this.opt.patient = {'patientAvg'};
            this.opt.sensorNoiseType = 'none';
            this.opt.sensorNoiseValue = 0;
            this.opt.useTreatments = true;
            this.opt.mealVariability = 0.0;
            this.opt.basalGlucose = 6.5;
            this.opt.initialGlucose = NaN;
            this.opt.RNGSeed = -1;
            
            if exist('options', 'var')
                f = fields(this.opt);
                for i = 1:numel(f)
                    if isfield(options, f{i})
                        this.opt.(f{i}) = options.(f{i});
                    end
                end
            end
            
            % Set patient name.
            this.name = this.opt.name;
            
            if this.opt.RNGSeed > 0
                rng(this.opt.RNGSeed);
            end
            
            % Basal Glucose (mmol/L).
            if this.opt.basalGlucose < 0
                this.param.GBasal = 6.5 + 1.0 * randn(1);
                while this.param.GBasal < 5 || this.param.Gb > 8
                    this.param.GBasal = 6.5 + 1.0 * randn(1);
                end
            else
                this.param.GBasal = this.opt.basalGlucose;
            end
            
            % Generate patient parameter.
            if ismethod(this, this.opt.patient{1})
                eval(['this.', this.opt.patient{1}]);
            else
                error('Unkown patient type %s', this.opt.patient{1});
            end
            
            % init state
            this.state = this.getX0();
            this.stateHistory = zeros(length(this.state), this.stateHistorySize);
            this.stateHistory(:, end) = this.state;
            
            % sensor model
            this.CGM.lambda = 15.96; % Johnson parameter of recalibrated and synchronized sensor error
            this.CGM.epsilon = -5.471; % Johnson parameter of recalibrated and synchronized sensor error
            this.CGM.delta = 1.6898; % Johnson parameter of recalibrated and synchronized sensor error
            this.CGM.gamma = -0.5444; % Johnson parameter of recalibrated and synchronized sensor error
            this.CGM.error = 0;
            
            % Initialize meals.
            this.meals = struct([]);
        end
        
        function state = getState(this)
            state = this.state;
        end
        
        function prop = getProperties(this)
            prop = this.param;
        end
        
        function meas = getGlucoseMeasurement(this)
            meas = this.state(this.eGluMeas);
        end
        
        function updateState(this, startTime, endTime, infusions)
            % get infusions
            Ubasal = max(infusions.basalInsulin, 0);
            Ubolus = max(infusions.bolusInsulin, 0);
            
            % add meal
            meal = this.mealPlan.getMeal(startTime);
            if meal.value ~= 0
                this.meals(end+1).value = meal.value;
                this.meals(end).time = startTime;
                this.meals(end).TauM = max(min(this.param.TauM.*(1 + this.opt.mealVariability * randn(1)), 55), 15);
                this.meals(end).Bio = this.param.Bio;
            end
            exercise = this.exercisePlan.getExercise(startTime);
            if exercise.duration ~= 0
                this.exercises(end+1).time = startTime;
                this.exercises(end).duration = exercise.duration;
                this.exercises(end).intensity = exercise.intensity;
            end
            
            % last state
            X0 = this.state;
            
            % add Insluin bolus (Units)
            X0(this.eInsSub) = X0(this.eInsSub) + Ubolus;
            
            % simulate
            [~, Y_] = ode15s(@(t_, y_) this.model(t_, y_, Ubasal), ...
                [startTime, endTime], ...
                X0);
            this.state = Y_(end, :)';
            
            % Update sensor noise.
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
            
            % Add sensor noise.
            this.state(this.eGluMeas) = this.state(this.eGluInte) + this.CGM.error;
            
            % Add treatment.
            this.processTreatmentLogic(startTime);
            
            % save states in memory
            this.stateHistory(:, 1:end-1) = this.stateHistory(:, 2:end);
            this.stateHistory(:, end) = this.state;
            
            if this.firstIteration
                this.firstIteration = false;
            end
        end
    end
    
    methods (Access = private)
        function processTreatmentLogic(this, t)
            if this.opt.useTreatments
                meals_ = this.mealPlan.getMeal(max(t-30, this.mealPlan.simulationStartTime):this.mealPlan.simulationStepSize:t+20);
                treats_ = this.mealPlan.getTreatment(max(t-30, this.mealPlan.simulationStartTime):this.mealPlan.simulationStepSize:t);
                if sum(meals_.value) + sum(treats_) < 15 % if patient had or planing to have a meal
                    hypoThreshold = 3.9; % mmol/L.
                    prolongedHypoThreshold = 3.3; % mmol/L.
                    prolongedHypoDuration = floor(60/this.mealPlan.simulationStepSize) + 1; % index
                    if all(this.stateHistory(this.eGluPlas, end-prolongedHypoDuration:end) < prolongedHypoThreshold)
                        this.addTreatment(t, 30);
                    elseif all(this.stateHistory(this.eGluPlas, end-1:end) < hypoThreshold)
                        this.addTreatment(t, 15);
                    end
                end
            end
        end
        
        function X0 = getX0(this)
            % glucose measurement (mmol/l)
            if isnan(this.opt.initialGlucose)
                Gs0 = this.param.GBasal;
            elseif this.opt.initialGlucose < 0
                Gs0 = normrnd(7, 3.5);
                while Gs0 < 5 || Gs0 > 8
                    Gs0 = normrnd(7, 3.5);
                end
            else
                Gs0 = this.opt.initialGlucose;
            end
                        
            % sensor glucose (mmol/L)
            X0(this.eGluMeas) = Gs0;
            
            % Interstitial glucose (mmol/L)
            X0(this.eGluInte) = Gs0;
            
            % plasma glucose (mmol/L)
            X0(this.eGluPlas) = Gs0;
            
            % insulin effect (1 / min)
            X0(this.eInsAct) = (this.param.P3 / this.param.P2) * this.param.Ip0;
            
            % insulin plasma (U)
            X0(this.eInsPlas) = this.param.TauI * this.param.Ub0 / 60;
            
            % insulin subcutenous (U)
            X0(this.eInsSub) = this.param.TauI * this.param.Ub0 / 60;
            
            
            X0 = X0(:);
        end
        
        function dydt = model(this, t, y, u)
            dydt = zeros(size(y));
            
            % Subcutaneous insulin absorption subsystem (U)
            dydt(this.eInsSub) = -y(this.eInsSub) / this.param.TauI + u / 60;
            dydt(this.eInsPlas) = -y(this.eInsPlas) / this.param.TauI + y(this.eInsSub) / this.param.TauI;
            
            % Plasma insulin (mU/L)
            Ip = 1e3 * y(this.eInsPlas) / (this.param.MCR * this.param.w) / this.param.TauI;
            
            % check for exercise
            exercDur = 0;
            exercInt = 0;
            for e = 1:length(this.exercises)
                if this.exercises(e).time <= t && t < this.exercises(e).time + this.exercises(e).duration
                    exercInt = this.exercises(e).intensity;
                    exercDur = (t - this.exercises(e).time)/60;
                end
            end
            
            % Plasma insulin action subsystem (1/min)
            if exercInt > 0 % exercise
                dydt(this.eInsAct) = -this.param.P2 * y(this.eInsAct) + (1 + this.param.e2 * (exercInt + exercDur)) * this.param.P3 * Ip;
            else
                dydt(this.eInsAct) = -this.param.P2 * y(this.eInsAct) + this.param.P3 * Ip;
            end
            
            % Gut absorption subsystem (mmol/L/min).
            Um = 0;
            for m = 1:length(this.meals)
                Um = Um + ...
                    this.param.Km * this.meals(m).Bio * this.meals(m).value * ...
                    (t - this.meals(m).time) * exp(-(t - this.meals(m).time)/this.meals(m).TauM) / this.meals(m).TauM^2 / this.param.Vg;
            end
                        
            % Glucose kinetics subsystem (mmol/L)
            if exercInt > 0 % exercise
                dydt(this.eGluPlas) = -this.param.P1 * (1 + this.param.e1 * exercInt) * y(this.eGluPlas) ...
                    -y(this.eInsAct) * y(this.eGluPlas) ...
                    +this.param.P1 * this.param.Gb ...
                    +Um;
            else
                dydt(this.eGluPlas) = -this.param.P1 * y(this.eGluPlas) ...
                    -y(this.eInsAct) * y(this.eGluPlas) ...
                    +this.param.P1 * this.param.Gb ...
                    +Um;
            end
            
            % Glucose sensor (mmol/l)
            dydt(this.eGluInte) = (y(this.eGluPlas) - y(this.eGluInte)) / this.param.TauS;
        end
        
        function addTreatment(this, time, meal)
            % Append meal info to mealPlan.
            this.mealPlan.addTreatment(time, meal);
            
            % Consume the meal.
            this.meals(end+1).value = meal;
            this.meals(end).time = time;
            this.meals(end).TauM = 20;
            this.meals(end).Bio = this.param.Bio;
        end
    end
    
end
