classdef MDITherapy < InfusionController
    %MDITHERAPY Open loop therapy with multiple daily injections.
    
    properties(GetAccess = public, SetAccess = immutable)
        glucoseHistorySize = 100;
    end
    
    properties(GetAccess = public, SetAccess = private)
        opt; % Options configured by the user.
        
        glucoseHistory;
        
        bolusHistory;
        lastBolusTime;
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            
            defaultAns = struct();
            if ~exist('lastOptions', 'var')
                defaultAns.name = className;
                defaultAns.targetGlucose = 6.0;
                defaultAns.useFixedISF = false;
                defaultAns.insulinSensitivity = 2.5;
                defaultAns.mealBolus = true;
                defaultAns.correctionBolus = true;
            else
                defaultAns = lastOptions;
            end
            
            function toggleOptionValue(~, ~, handles, k)
                if get(handles(k, 1), 'Value') == 0
                    set(handles(k+1, 1), 'Enable', 'off')
                else
                    set(handles(k+1, 1), 'Enable', 'on')
                end
            end
            
            dlgTitle = 'Configure MDI Therapy';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Controller name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 110;
            
            prompt(end+1, :) = {'Target glucose:', 'targetGlucose', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 110;
            
            prompt(end+1, :) = {'Set patient insulin sensitivity factor:', 'useFixedISF', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).callback = @toggleOptionValue;
            formats(end, 1).size = 140;
            
            prompt(end+1, :) = {'', 'insulinSensitivity', 'mmol / (L U)'};
            formats(end, 2).type = 'edit';
            formats(end, 2).format = 'float';
            if defaultAns.useFixedISF
                formats(end, 2).enable = 'on';
            else
                formats(end, 2).enable = 'off';
            end
            formats(end, 2).size = 70;
            
            prompt(end+1, :) = {'Insulin duration:', 'insulinDuration', 'min'};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 110;
            
            prompt(end+1, :) = {'Insulin peak time:', 'insulinPeakTime', 'min'};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 110;
            
            prompt(end+1, :) = {'Provide meal boluses.', 'mealBolus', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).size = 110;
            
            prompt(end+1, :) = {'Provide correction boluses with rules...', 'correctionBolus', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).size = 100;
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, defaultAns);
            
            options = [];
            if ~cancelled
                options = answer;
            end
        end
    end
    
    methods(Access = public)
        function this = MDITherapy(simulationStartTime, simulationDuration, simulationStepSize, patient, options)
            this@InfusionController(simulationStartTime, simulationDuration, simulationStepSize, patient);
            
            % Parse options.
            this.opt = struct();
            this.opt.name = this.name;
            this.opt.targetGlucose = 6.0;
            this.opt.useFixedISF = false;
            this.opt.insulinSensitivity = 2.5;
            this.opt.mealBolus = true;
            this.opt.correctionBolus = true;
            
            if exist('options', 'var')
                f = fields(this.opt);
                for i = 1:numel(f)
                    if isfield(options, f{i})
                        this.opt.(f{i}) = options.(f{i});
                    end
                end
            end
            
            this.name = this.opt.name;
            
            % Customize ISF per patient if useFixedISF is false.
            if ~this.opt.useFixedISF
                prop = this.patient.getProperties();
                if isfield(prop, 'TDD')
                    this.opt.insulinSensitivity = 110.0 / prop.TDD;
                end
                this.opt.insulinSensitivity = min(this.opt.insulinSensitivity, 7.0);
                this.opt.insulinSensitivity = max(this.opt.insulinSensitivity, 0.5);
            end
            
            % Initialize state.
            this.glucoseHistory = nan(1, this.glucoseHistorySize);
            
            % Initialize bolus history.
            this.bolusHistory.index = 0;
            this.bolusHistory.value = [];
            this.bolusHistory.time = [];
            
            % Initialize last time of bolus
            this.lastBolusTime = -inf;
        end
        
        function infusions = getInfusions(this, time)
            % Initialize infusions.
            infusions.bolusInsulin = 0;
            infusions.basalInsulin = 0;
            
            % Save glucose history
            glucose = this.patient.getGlucoseMeasurement();
            this.glucoseHistory(:, 1:end-1) = this.glucoseHistory(:, 2:end);
            this.glucoseHistory(:, end) = glucose;
            
            % Get patient properties.
            prop = this.patient.getProperties();
            pumpBasals = prop.pumpBasals.value;
            
            % Compute basal.
            if isfield(prop, 'pumpBasals')
                infusions.basalInsulin = round(mean(pumpBasals), 2);
            end
            
            % Calculate meal bolus:
            % Bolus covers CHO + correction of high/low glucose.
            if this.opt.mealBolus
                meal = this.patient.getMeal(time);
                if meal.value > 0
                    if isfield(prop, 'carbFactors')
                        idx = find(prop.carbFactors.time <= mod(time, 24*60), 1, 'last');
                        if ~isempty(idx)
                            carbFactor = prop.carbFactors.value(idx);
                        else
                            carbFactor = prop.carbFactors.value(end);
                        end
                    else
                        carbFactor = 12;
                    end
                    
                    if this.opt.correctionBolus
                        correctionBolus = (glucose - this.opt.targetGlucose) / this.opt.insulinSensitivity;
                        infusions.bolusInsulin = round(2*( ...
                            meal.value / carbFactor + ...
                            max(correctionBolus, 0)), 1) / 2;
                    else
                        infusions.bolusInsulin = round(2*( ...
                            meal.value / carbFactor), 1) / 2;
                    end
                    
                    if infusions.bolusInsulin < 0
                        infusions.bolusInsulin = 0.0;
                    end
                end
            end
            
            % Add bolus to history.
            if infusions.bolusInsulin > 0
                this.bolusHistory.index = this.bolusHistory.index + 1;
                this.bolusHistory.value(this.bolusHistory.index) = infusions.bolusInsulin;
                this.bolusHistory.time(this.bolusHistory.index) = time;
                this.lastBolusTime = time;
            end
        end
        
        function setInfusions(this, time, infusions)
            if infusions.bolusInsulin > 0
                this.lastBolusTime = time;
            end
        end
    end
end
