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
    
    properties (GetAccess = public, SetAccess = immutable)
        stateHistorySize = 1000;
        
        % State enumeration.
        eInsSub1 = 1;
        eInsSub2 = 2;
        eInsPlas = 3;
        eInsActT = 4;
        eInsActD = 5;
        eInsActE = 6;
        eGutAbs = 7;
        eGluPlas = 8;
        eGluComp = 9;
        eGluInte = 10;
        eGluMeas = 11;
    end
    
    properties (GetAccess = public, SetAccess = protected)
        opt; % Options configured by the user.
        param; % Parameters configured by the specific patient model (patient0, patient1, ...).
        
        state;
        stateHistory;
        
        stateScale = [];
        
        meals;
        glucagon;
        CGM; % Recalibrated and synchronized sensor error.
        variability; % Intra-patient variability.
        propertiesError;
        dailyCarbsCountingError; % errors in carb counting which be applied in each day
        
        firstIteration = true;
    end
    
    properties (Dependent)
        ID;
    end
    
    methods
        function ID_ = get.ID(this)
            ID_ = str2double(regexp(this.name, '\d+.?', 'match'));
        end
    end
    
    methods (Static)
        function options = configure(className, lastOptions)
            if ~exist('lastOptions', 'var')
                lastOptions = struct();
                lastOptions.name = className;
                lastOptions.patient = {'patientAvg'};
                lastOptions.sensorNoiseType = {'none'};
                lastOptions.sensorNoiseValue = 0.0;
                lastOptions.intraVariability = 0.0;
                lastOptions.mealVariability = 0.0;
                lastOptions.initialGlucose = 6.5;
                lastOptions.basalGlucose = 6.5;
                lastOptions.useTreatments = true;
                lastOptions.RNGSeed = -1;
            end
            
            dlgTitle = 'Configure Hovorka Patient';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Patient Name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200; % Automatically assign the height.
            
            prompt(end+1, :) = {'Patient model:', 'patient', evalc(['help ', className, '.', lastOptions.patient{1}])};
            formats(end+1, 1).type = 'list';
            formats(end, 1).style = 'listbox';
            formats(end, 1).format = 'text'; % Answer will give value shown in items, disable to get integer.
            formats(end, 1).items = {};
            m = methods (className);
            for i = 1:numel(m)
                startIndex = regexp(m{i}, '^patient[\w]+$');
                if startIndex == 1
                    formats(end, 1).items{end+1} = m{i};
                end
            end
            formats(end, 1).limits = [1, 1]; % One-select.
            formats(end, 1).size = [150, 100];
            formats(end, 1).callback = @(hObj, ~, handles, k) ...
                set(handles(k, 3), 'String', evalc(['help ', className, '.', hObj.String{hObj.Value}]));
            formats(end, 1).span = [1, 2];
            
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
            formats(end, 1).span = [1, 2];
            
            prompt(end+1, :) = {'Patient has non-optimal basal-bolus parameter', 'wrongPumpParam', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).span = [1, 2];
            
            prompt(end+1, :) = {'Patient makes carb counting errors', 'carbsCountingError', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).span = [1, 2];
            
            prompt(end+1, :) = {'RNG for reproducibility (-1 for random value)', 'RNGSeed', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 200;
            formats(end, 1).span = [1, 2];
            
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
            this.opt.patient = {'patientAvg'};
            this.opt.sensorNoiseType = 'none';
            this.opt.sensorNoiseValue = 0.4;
            this.opt.intraVariability = 0.0;
            this.opt.mealVariability = 0.0;
            this.opt.basalGlucose = 6.5;
            this.opt.initialGlucose = 6.5;
            this.opt.initialInsulinOnBoard = 0.0;
            this.opt.initialState = [];
            this.opt.useTreatments = true;
            this.opt.wrongPumpParam = false;
            this.opt.pumpBasalsError = struct('time', [], 'value', []);
            this.opt.carbFactorsError = struct('time', [], 'value', []);
            this.opt.carbsCountingError = false;
            this.opt.dailyCarbsCountingError = struct('time', [], 'value', []);
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
            
            % Set Rng for reproducibility
            if this.opt.RNGSeed > 0
                rng(mod(this.simulationStartTime*this.opt.RNGSeed, 999983));
            end
            
            % Basal Glucose (mmol/L).
            if this.opt.basalGlucose < 0
                this.param.GBasal = 6.5 + 1.0 * randn(1);
                while this.param.GBasal < 5 || this.param.GBasal > 8
                    this.param.GBasal = 6.5 + 1.0 * randn(1);
                end
            else
                this.param.GBasal = this.opt.basalGlucose;
            end
            
            % Generate patient parameter.
            if isstruct(this.opt.patient{1})
                for f = fieldnames(this.opt.patient{1})'
                    this.param.(f{1}) = this.opt.patient{1}.(f{1});
                end
            elseif ismethod(this, this.opt.patient{1})
                eval(['this.', this.opt.patient{1}]);
            else
                db = dbstack('-completenames');
                dir = fileparts(db(1).file);
                load([dir, filesep, this.opt.patient{1}, '.mat'], 'param');
                if numel(param) > 1 % mat file with multiple patients
                    if isempty(this.ID) || isnan(this.ID)
                        warning('[HovorkaPatient][%s] Couldn''t read patient number from patient patient name. Will use a random number', this.opt.patient{1});
                        ID_ = randi(100);
                    else
                        ID_ = this.ID;
                    end
                    if ID_ > numel(param)
                        warning('[HovorkaPatient][%s] Patient number is outside possible range.', this.opt.patient{1});
                        ID_ = mod(ID_-1, numel(param)) + 1;
                    end
                    for f = fieldnames(param(ID_))'
                        this.param.(f{1}) = param(ID_).(f{1});
                    end
                else
                    for f = fieldnames(param)'
                        this.param.(f{1}) = param.(f{1});
                    end
                end
            end
            
            if ~isfield(this.param, 'Rcl')
                this.param.RTh = 14; % Renal clearance threshold (mmol/L).
                this.param.RCl = lognrnd(log(1 / (2 * 60)), 0.2); % Renal clearance rate (1/min).
            end

            % Glucagon submodel.
            if ~isfield(this.param, 'TGlu')
                this.param.TauGlu = lognrnd(log(19), 0.2); % Time-to-maximum of glucagon absorption (min).
                this.param.TGlu = lognrnd(log(0.0012), 0.2); % Glucagon sensitivity (mL/pg).
                this.param.MCRGlu = lognrnd(log(0.012), 0.2); % Metabolic clearance rate of glucagon (L/kg/min).
            end

            % Set patient parameters.
            this.param.carbFactors.value = this.param.carbF;
            this.param.carbFactors.time = 0;
            this.param.pumpBasals.value = this.param.Ub;
            this.param.pumpBasals.time = 0;
            
            % Generate pump parameter error.
            this.applyWrongPumpParam();
            
            % Apply carbs counting errors
            this.applyCarbsCountingErrors();
            
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
            
            % Set scaling for states.
            this.stateScale = [; ...
                1.0; ... % U
                1.0; ... % U
                1e-6 * 60 * this.param.ke * (this.param.Vi * this.param.w); ... % mU / L -> U
                1.0; ... % 1/min
                1.0; ... % 1/min
                1.0; ... % no-units
                60 / this.param.Vg; ... umol/kg/min -> mmol/L
                1 / this.param.Vg; ... % umol/kg -> mmol/L
                1 / this.param.Vg; ... % umol/kg -> mmol/L
                1.0; ... % mmol/L
                1.0; ... % mmol/L
                ];
        end
        
        function prop = getProperties(this)
            prop = this.param;
            
            % Note that TDD update is removed. TODO put it back.
            
            if isfield(this.propertiesError, 'pumpBasals') && ~isempty(this.propertiesError.pumpBasals.time)
                prop.pumpBasals.time = this.propertiesError.pumpBasals.time;
                prop.pumpBasals.value = round((1 + this.propertiesError.pumpBasals.value).*prop.pumpBasals.value, 2);
            end
            
            if isfield(this.propertiesError, 'carbFactors') && ~isempty(this.propertiesError.carbFactors.time)
                prop.carbFactors.time = this.propertiesError.carbFactors.time;
                prop.carbFactors.value = round(2*(1 + this.propertiesError.carbFactors.value).*prop.carbFactors.value) / 2;
            end
        end
        
        function glucose = getGlucoseMeasurement(this)
            glucose = this.state(this.eGluMeas);
        end
        
        function tracerInfo = getTracerInfo(this)
            tracerInfo = getTracerInfo@VirtualPatient(this);
            
            tracerInfo.plasmaGlucose = this.state(this.eGluPlas) / this.param.Vg; % umol/kg -> mmol/L
            tracerInfo.rateGutAbsorption = this.state(this.eGutAbs) * this.param.TauM / this.param.Vg; % umol/kg/min -> mmol/L
            tracerInfo.plasmaInsulin = this.state(this.eInsPlas) * this.param.Vi * this.param.w * 1e-3; % mU/L -> U/ml
        end
        
        function updateState(this, startTime, endTime, infusions)
            % Reset random number generator.
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
            
            if rem(startTime, 24*60) == this.simulationStartTime || this.firstIteration
                
                % Add intra-variability.
                if this.opt.intraVariability > 0
                    % Reset intra-patient variability.
                    for fn = fieldnames(this.variability)'
                        if isstruct(this.variability.(fn{1}))
                            this.variability.(fn{1}).phase = 3 * 60 * rand(1);
                            this.variability.(fn{1}).period = 3 * 60 + 0.5 * 60 * (rand(1) - 0.5);
                        end
                    end
                end
            end
            
            % Add meal.
            meal = this.mealPlan.getMeal(startTime);
            if meal.value > 0
                this.meals(end+1).value = meal.value;
                this.meals(end).time = startTime;
                if meal.glycemicLoad < 10
                    this.meals(end).gutAbsorptionModel = @this.gut2CompModel;
                    this.meals(end).TauM = max(min(this.param.TauM.*(1 + 0.2 * this.opt.mealVariability * randn(1)), 55), 15);
                    this.meals(end).Delay = 0;
                else
                    this.meals(end).gutAbsorptionModel = @this.gut4CompDelayedModel;
                    this.meals(end).TauM1 = max(min(this.param.TauM*0.7*(1 + 0.2 * this.opt.mealVariability * randn(1)), min(1.4/this.param.ka, 55)), 15);
                    this.meals(end).TauM2 = max(min(this.param.TauM*1.4*(1 + 0.2 * this.opt.mealVariability * randn(1)), 1.4/this.param.ka), 30);
                    if this.opt.mealVariability > 0.25
                        this.meals(end).Delay1 = 15 * rand(1);
                        this.meals(end).Delay2 = 5 + 30 * rand(1);
                        this.meals(end).Prop = 0.3 + 0.3 * rand(1);
                    else
                        this.meals(end).Delay1 = 5;
                        this.meals(end).Delay2 = 25;
                        this.meals(end).Prop = 0.4;
                    end
                end
                if this.opt.mealVariability > 0.5
                    this.meals(end).Bio = this.param.Bio * (0.8 + 0.4 * rand(1));
                else
                    this.meals(end).Bio = this.param.Bio;
                end
            end
            
            % Add insulin bolus.
            this.state(this.eInsSub1) = this.state(this.eInsSub1) + Ubolus;
            
            % Add glucagon bolus.
            if Ugbolus ~= 0
                this.glucagon(end+1).value = Ugbolus;
                this.glucagon(end).time = startTime;
            end
            
            % Apply intra-variability.
            if this.opt.intraVariability > 0
                this.applyIntraVariability(startTime);
            end
            
            % Simulate.
            [~, Y] = ode15s(@(t, y) this.model(t, y, Ubasal), ...
                [startTime, endTime], ...
                this.state);
            
            this.state = Y(end, :)';
            Um = 0;
            for m = 1:length(this.meals)
                Um = Um + this.meals(m).gutAbsorptionModel(endTime, this.meals(m));
            end
            this.state(this.eGutAbs) = Um;
            
            % Update sensor model
            if this.firstIteration
                this.CGM.error = 0;
            else
                switch lower(char(this.opt.sensorNoiseType))
                    case 'johnson'
                        sensorNoise = 0.7 * (this.CGM.error + this.opt.sensorNoiseValue * randn(1));
                        this.CGM.error = (10 / this.param.MCHO) * (this.CGM.epsilon + ...
                            this.CGM.lambda * sinh((sensorNoise - this.CGM.gamma)/this.CGM.delta));
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
            if this.state(this.eGluMeas) > 22.2
                this.state(this.eGluMeas) = 22.2;
            end
            if this.state(this.eGluMeas) < 2.2
                this.state(this.eGluMeas) = 2.2;
            end
            
            % Add treatment.
            this.processTreatmentLogic(startTime);
            
            % Save states in history.
            this.stateHistory(:, 1:end-1) = this.stateHistory(:, 2:end);
            this.stateHistory(:, end) = this.state;
            
            if this.firstIteration
                this.firstIteration = false;
            end
        end
        
        function meal = getMeal(this, time)
            meal = this.getMeal@VirtualPatient(time);
            
            % This patient can forget to announce meals to the controller.
            if isfield(meal, 'announced')
                meal.value = meal.announced .* meal.value;
                meal.glycemicLoad = meal.announced .* meal.glycemicLoad;
            end
            
            if this.opt.carbsCountingError
                meal.value(meal.value > 0) = max(round(meal.value(meal.value > 0).* ...
                    (1 + this.dailyCarbsCountingError((time(meal.value > 0) - this.simulationStartTime)/(this.simulationStepSize)+1))), 0);
            end
        end
    end
    
    methods (Access = protected)
        function processTreatmentLogic(this, t)
            if this.opt.useTreatments
                meals_ = this.mealPlan.getMeal(max(t-30, this.mealPlan.simulationStartTime):this.mealPlan.simulationStepSize:t+20);
                treats_ = this.mealPlan.getTreatment(max(t-30, this.mealPlan.simulationStartTime):this.mealPlan.simulationStepSize:t);
                if sum(meals_.value) + sum(treats_) < 15 % if patient had or planing to have a meal
                    hypoThreshold = 2.8; % mmol/L.
                    prolongedHypoThreshold = 3.3; % mmol/L.
                    prolongedHypoDuration = floor(60/this.mealPlan.simulationStepSize) + 1; % index
                    if all(this.stateHistory(this.eGluPlas, end-prolongedHypoDuration:end)/this.param.Vg < prolongedHypoThreshold)
                        this.addTreatment(t, 30);
                    elseif all(this.stateHistory(this.eGluPlas, end-1:end)/this.param.Vg < hypoThreshold)
                        this.addTreatment(t, 15);
                    end
                end
            end
        end
        
        function applyIntraVariability(this, t)
            alp = 0.7; % Filter parameter changes.
            
            for fn = fieldnames(this.variability)'
                if isstruct(this.variability.(fn{1}))
                    target = this.param.(fn{1}) * (1 + 0.1 * sin(2*pi*(t + this.variability.(fn{1}).phase)/(this.variability.(fn{1}).period)));
                    this.variability.(fn{1}).val = (1 - alp) * this.variability.(fn{1}).val + alp * target;
                end
            end
        end
        
        function applyWrongPumpParam(this)
            if this.opt.wrongPumpParam > 0
                fields = {'pumpBasals', 'carbFactors'};
                defaultErrorInterval = [4 * 60, 6 * 60, 6 * 60];
                for k = 1:length(fields)
                    if ~isempty(this.opt.([fields{k}, 'Error']).time)
                        error_.time = this.opt.([fields{k}, 'Error']).time;
                        error_.value = this.opt.([fields{k}, 'Error']).value;
                    else % Choose random pump errors
                        error_.time = unique(floor((0:this.simulationStepSize:1440 - this.simulationStepSize)/defaultErrorInterval(k))) * defaultErrorInterval(k);
                        error_.value = 0.4 * this.opt.wrongPumpParam * randn(size(error_.time));
                    end
                    
                    this.propertiesError.(fields{k}).time = error_.time;
                    this.propertiesError.(fields{k}).value = error_.value;
                end
            end
        end
        
        function applyCarbsCountingErrors(this)
            if this.opt.carbsCountingError > 0
                time = this.simulationStartTime:this.simulationStepSize:(this.simulationStartTime + this.simulationDuration);
                this.dailyCarbsCountingError = nan(this.simulationDuration/this.simulationStepSize+1, 1);
                if ~isempty(this.opt.dailyCarbsCountingError.time)
                    for n = 1:length(time)
                        idx = find(this.opt.dailyCarbsCountingError.time <= time(n), 1, 'last');
                        if ~isempty(idx)
                            this.dailyCarbsCountingError(n) = this.opt.dailyCarbsCountingError.value(idx);
                        else
                            this.dailyCarbsCountingError(n) = this.opt.dailyCarbsCountingError.value(end);
                        end
                    end
                else % Choose random carb counting erros
                    dailyCarbsCountingError_.time = unique(floor(time/(4 * 60))) * (4 * 60);
                    dailyCarbsCountingErrorValue = this.opt.carbsCountingError * (rand(length(unique(mod(dailyCarbsCountingError_.time, 1440))), 1) - 0.5);
                    dailyCarbsCountingErrorValue = dailyCarbsCountingErrorValue(mod(dailyCarbsCountingError_.time, 1440)/(4 * 60)+1);
                    dailyCarbsCountingError_.value = dailyCarbsCountingErrorValue .* (1 + 0.4 * randn(size(dailyCarbsCountingErrorValue)));
                    
                    for n = 1:length(time)
                        idx = find(dailyCarbsCountingError_.time <= time(n), 1, 'last');
                        if ~isempty(idx)
                            this.dailyCarbsCountingError(n) = dailyCarbsCountingError_.value(idx);
                        else
                            this.dailyCarbsCountingError(n) = dailyCarbsCountingError_.value(end);
                        end
                    end
                end
            end
        end
        
        function Um = gut4CompDelayedModel(this, t, meal)
            if t > (meal.time + meal.Delay1)
                Qm1 = (t - meal.time - meal.Delay1) * exp(-(t - meal.time - meal.Delay1)/meal.TauM1) / meal.TauM1^2;
            else
                Qm1 = 0;
            end
            if t > (meal.time + meal.Delay2)
                Qm2 = (t - meal.time - meal.Delay2) * exp(-(t - meal.time - meal.Delay2)/meal.TauM2) / meal.TauM2^2;
            else
                Qm2 = 0;
            end
            
            Um = (1e6 / (this.param.w * this.param.MCHO)) * meal.Bio * meal.value * (meal.Prop * Qm1 + (1 - meal.Prop) * Qm2);
        end
        
        function Um = gut2CompModel(this, t, meal)
            if t > (meal.time + meal.Delay)
                Um = (1e6 / (this.param.w * this.param.MCHO)) * meal.Bio * meal.value * ...
                    (t - meal.time - meal.Delay) * exp(-(t - meal.time - meal.Delay)/meal.TauM) / meal.TauM^2;
            else
                Um = 0;
            end
        end
        
        function initialState = getInitialState(this)
            if ~isempty(this.opt.initialState)
                initialState = this.opt.initialState;
            else
                initialState = nan(this.eGluMeas, 1);
                
                % Glucose measurement (mmol/L).
                if this.opt.initialGlucose < 0
                    Gs0 = this.param.GBasal * (1 + 0.7 * randn(1));
                    while Gs0 < 4 || Gs0 > 14
                        Gs0 = this.param.GBasal * (1 + 0.7 * randn(1));
                    end
                else
                    Gs0 = this.opt.initialGlucose;
                end
                
                initialState(this.eGluPlas) = Gs0 * this.param.Vg;
                initialState(this.eGluMeas) = Gs0;
                initialState(this.eGluInte) = Gs0;
                
                % On-board bolus.
                if this.opt.initialInsulinOnBoard < 0
                    Qb = 2.5 * (rand(1) - 0.5);
                    while Qb < -0.8 * this.param.Ub
                        Qb = 2.5 * (rand(1) - 0.5);
                    end
                else
                    Qb = this.opt.initialInsulinOnBoard;
                end
                
                % Plasma insulin kinetics subsystem (mU/L).
                initialState(this.eInsPlas) = (this.param.Ub + Qb) / (this.param.ke / (1e6 * this.param.ka / (this.param.Vi * this.param.w)));
                
                % Insulin actions.
                initialState(this.eInsActT) = this.param.St * initialState(this.eInsPlas);
                initialState(this.eInsActD) = this.param.Sd * initialState(this.eInsPlas);
                initialState(this.eInsActE) = this.param.Se * initialState(this.eInsPlas);
                
                % Glucose plasma (umol/kg).
                Q10 = Gs0 * this.param.Vg;
                Q20 = Q10 * initialState(this.eInsActT) / (initialState(this.eInsActD) + this.param.k12); % umol/kg.
                initialState(this.eGluComp) = Q20;
                
                % Subcutenous insulin.
                initialState(this.eInsSub1) = this.param.Ub / 60 / this.param.ka;
                initialState(this.eInsSub2) = initialState(this.eInsSub1);
                
                % Reset Gut Absorption
                initialState(this.eGutAbs) = 0;
            end
            
            initialState = initialState(:);
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
            this.meals(end).Delay = 0;
            this.meals(end).Bio = 1.0;
        end
    end
    
end
