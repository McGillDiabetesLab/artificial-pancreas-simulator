classdef PumpTherapy < InfusionController
    %PUMPTHERAPY  Open loop therapy with a pump.
    
    properties (GetAccess = public, SetAccess = immutable)
        glucoseHistorySize = 100;
    end
    
    properties (GetAccess = public, SetAccess = private)
        opt; % Options configured by the user.
        
        glucoseHistory;
        filteredGlucoseHistory;
        dGlucoseHistory;
        
        bolusHistory;
        
        pumpShutOff;
        lastBolusTime;
    end
    
    methods (Static)
        function options = configure(className, lastOptions)
            
            defaultAns = struct();
            defaultAns.corrBolusTable = cell(20, 3);
            if ~exist('lastOptions', 'var')
                defaultAns.name = className;
                defaultAns.targetGlucose = 6.5;
                defaultAns.useFixedISF = false;
                defaultAns.insulinSensitivity = 2.5;
                defaultAns.insulinDuration = 3.5 * 60;
                defaultAns.insulinPeakTime = 75;
                defaultAns.mealBolus = true;
                defaultAns.hypoPumpShutoff = false;
                defaultAns.dGlucosePumpShutoffThresh = 0.03;
                defaultAns.correctionBolus = true;
                defaultAns.corrBolusTable(1, :) = {'Default', '15.0', '0.0'};
            else
                f = fields(lastOptions);
                for i = 1:numel(f)
                    if strcmp(f{i}, 'corrBolusRules')
                        for k = 1:numel(lastOptions.corrBolusRules)
                            defaultAns.corrBolusTable(k, :) = { ...
                                lastOptions.corrBolusRules(k).name, ...
                                num2str(lastOptions.corrBolusRules(k).glucoseThresh), ...
                                num2str(lastOptions.corrBolusRules(k).dGlucoseThresh)};
                        end
                    else
                        defaultAns.(f{i}) = lastOptions.(f{i});
                    end
                end
            end
            
            function toggleOptionValue(~, ~, handles, k)
                if get(handles(k, 1), 'Value') == 0
                    set(handles(k+1, 1), 'Enable', 'off')
                else
                    set(handles(k+1, 1), 'Enable', 'on')
                end
            end
            
            dlgTitle = 'Configure Basal-Bolus Therapy';
            
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
            
            prompt(end+1, :) = {'Automatically shut off pump when hypo...', 'hypoPumpShutoff', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).callback = @toggleOptionValue;
            formats(end, 1).size = 110;
            
            prompt(end+1, :) = {'at a glucose rate of change threshold of', 'dGlucosePumpShutoffThresh', 'mmol / (L min)'};
            formats(end, 2).type = 'edit';
            formats(end, 2).format = 'float';
            if defaultAns.hypoPumpShutoff
                formats(end, 2).enable = 'on';
            else
                formats(end, 2).enable = 'off';
            end
            formats(end, 2).size = 150;
            
            prompt(end+1, :) = {'Provide correction boluses with rules...', 'correctionBolus', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).callback = @toggleOptionValue;
            formats(end, 1).size = 100;
            
            prompt(end+1, :) = {'', 'corrBolusTable', ''};
            formats(end, 2).type = 'table';
            formats(end, 2).format = {'char', 'char', 'char'};
            formats(end, 2).items = {'Rule name', 'Glucose thresh (mmol/L)', 'Glucose ROC thresh (mmol/(L min))'};
            if defaultAns.correctionBolus
                formats(end, 2).enable = 'on';
            else
                formats(end, 2).enable = 'off';
            end
            formats(end, 2).size = [460, 95];
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, defaultAns);
            
            options = [];
            if ~cancelled
                f = fields(answer);
                for i = 1:numel(f)
                    if strcmp(f{i}, 'corrBolusTable')
                        options.corrBolusRules = struct();
                        for j = 1:size(answer.corrBolusTable, 1)
                            if (~isempty(answer.corrBolusTable{j, 2}))
                                options.corrBolusRules(j).name = answer.corrBolusTable{j, 1};
                                options.corrBolusRules(j).glucoseThresh = str2double(answer.corrBolusTable{j, 2});
                                if (~isempty(answer.corrBolusTable{j, 3}))
                                    options.corrBolusRules(j).dGlucoseThresh = str2double(answer.corrBolusTable{j, 3});
                                else
                                    options.corrBolusRules(j).dGlucoseThresh = 0.0;
                                end
                            end
                        end
                    else
                        options.(f{i}) = answer.(f{i});
                    end
                end
            end
        end
    end
    
    methods (Access = public)
        function this = PumpTherapy(simulationStartTime, simulationDuration, simulationStepSize, patient, options)
            this@InfusionController(simulationStartTime, simulationDuration, simulationStepSize, patient);
            
            % Parse options.
            this.opt = struct();
            this.opt.name = this.name;
            this.opt.targetGlucose = 6.5;
            this.opt.useFixedISF = false;
            this.opt.insulinSensitivity = 2.5;
            this.opt.insulinDuration = 3.5 * 60;
            this.opt.insulinPeakTime = 75;
            this.opt.mealBolus = true;
            this.opt.hypoPumpShutoff = false;
            this.opt.dGlucosePumpShutoffThresh = 0.05;
            this.opt.correctionBolus = true;
            this.opt.corrBolusRules = struct([]);
            this.opt.corrBolusRules(1).name = 'Default';
            this.opt.corrBolusRules(1).glucoseThresh = 15.0;
            this.opt.corrBolusRules(1).dGlucoseThresh = 0.0;
            this.opt.temporalBasal = struct('time', [], 'type', [], 'value', [], 'duration', []);
            this.opt.bolusCalculatorError = struct('time', [], 'value', []);
            
            if exist('options', 'var')
                f = fields(this.opt);
                for i = 1:numel(f)
                    if isfield(options, f{i})
                        this.opt.(f{i}) = options.(f{i});
                    end
                end
            end
            
            this.name = this.opt.name;
            
            % Initialize state.
            this.glucoseHistory = nan(1, this.glucoseHistorySize);
            this.filteredGlucoseHistory = nan(1, this.glucoseHistorySize);
            this.dGlucoseHistory = nan(1, this.glucoseHistorySize);
            
            % Initialize bolus history.
            this.bolusHistory.index = 0;
            this.bolusHistory.value = [];
            this.bolusHistory.time = [];
            
            % Initialize pump shut-off flag.
            this.pumpShutOff = false;
            
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
            
            % Filter glucose values and compute glucose derivative
            if ~isnan(glucose)
                filteredGlucose = glucose;
                if all(~isnan(this.filteredGlucoseHistory(:, end-1:end)))
                    % We use an IIR filter with the transfer function
                    % H(z) = (1-alpha)^2 / (1 - alpha z^(-1) - alpha (1 - alpha) z^(-2))
                    % where alpha is a tuning parameter.
                    % For more details, see
                    % https://en.wikipedia.org/wiki/Infinite_impulse_response.
                    alph = 0.25;
                    filteredGlucose = ((1 - alph)^2) * glucose + alph * ...
                        (this.filteredGlucoseHistory(:, end) + (1 - alph) * this.filteredGlucoseHistory(:, end-1));
                end
                this.filteredGlucoseHistory(:, 1:end-1) = this.filteredGlucoseHistory(:, 2:end);
                this.filteredGlucoseHistory(:, end) = filteredGlucose;
                
                % For the glucose derivative (rate of change), we use the
                % second order backward finite difference.
                % For more details, see
                % https://en.wikipedia.org/wiki/Finite_difference_coefficient.
                dGlucose = 0;
                if all(~isnan(this.filteredGlucoseHistory(:, end-2:end)))
                    dGlucose = (3 * filteredGlucose - 4 * this.filteredGlucoseHistory(:, end-1) + ...
                        this.filteredGlucoseHistory(:, end-2)) / (2 * this.simulationStepSize);
                end
                this.dGlucoseHistory(:, 1:end-1) = this.dGlucoseHistory(:, 2:end);
                this.dGlucoseHistory(:, end) = dGlucose;
            else
                this.filteredGlucoseHistory(:, 1:end-1) = this.filteredGlucoseHistory(:, 2:end);
                this.filteredGlucoseHistory(:, end) = glucose;
                this.dGlucoseHistory(:, 1:end-1) = this.dGlucoseHistory(:, 2:end);
                this.dGlucoseHistory(:, end) = 0;
            end
            
            % Get patient properties.
            prop = this.patient.getProperties();
            
            % Compute ISF
            if ~this.opt.useFixedISF
                if isfield(prop, 'insulinSensitivity')
                    ISFs = prop.insulinSensitivity.value;
                    idx = find(prop.insulinSensitivity.time <= mod(time, 24*60), 1, 'last');
                    if ~isempty(idx)
                        ISF = ISFs(idx);
                    else
                        ISF = ISFs(end);
                    end
                elseif isfield(prop, 'TDD')
                    ISF = 110.0 / prop.TDD;
                    ISF = min(ISF, 7.5);
                    ISF = max(ISF, 0.5);
                end
            else
                ISF = this.opt.insulinSensitivity;
            end
            
            if isfield(prop, 'targetGlucose')
                targetGlucose = prop.targetGlucose;
            else
                targetGlucose = this.opt.targetGlucose;
            end
            
            % Compute basal.
            if isfield(prop, 'pumpBasals')
                pumpBasals = prop.pumpBasals.value;
                idx = find(prop.pumpBasals.time <= mod(time, 24*60), 1, 'last');
                if ~isempty(idx)
                    Ub = pumpBasals(idx);
                else
                    Ub = pumpBasals(end);
                end
            else % Use a default basal.
                Ub = 1.0; % U/h.
            end
            if ~isempty(this.opt.temporalBasal.time)
                idx = find(this.opt.temporalBasal.time <= mod(time, 24*60), 1, 'last');
                if ~isempty(idx)
                    if time < this.opt.temporalBasal.time(idx) + this.opt.temporalBasal.duration(idx)
                        switch lower(this.opt.temporalBasal.type{idx})
                            case 'rate'
                                Ub = this.opt.temporalBasal.value(idx);
                            case 'percent'
                                Ub = Ub * this.opt.temporalBasal.value(idx);
                        end
                    end
                end
            end
            infusions.basalInsulin = round(Ub, 2);
            
            % Insulin pump shut-off logic.
            if this.opt.hypoPumpShutoff
                if this.pumpShutOff && ...
                        ((filteredGlucose > 3.9 && ...
                        mean(this.dGlucoseHistory(end-1:end)) > abs(this.opt.dGlucosePumpShutoffThresh)) || ...
                        filteredGlucose > 4.7)
                    this.pumpShutOff = false;
                end
                
                if this.pumpShutOff || ...
                        ((filteredGlucose < 5.5 && ...
                        mean(this.dGlucoseHistory(end-1:end)) < -abs(this.opt.dGlucosePumpShutoffThresh)) || ...
                        filteredGlucose < 3.9)
                    this.pumpShutOff = true;
                    infusions.basalInsulin = 0;
                end
            end
            
            % Insulin On Board.
            insulinOnBoard = 0;
            if this.bolusHistory.index > 0
                for b = 1:this.bolusHistory.index
                    insulinOnBoard = insulinOnBoard + ...
                        this.bolusHistory.value(b) * this.scalableExpIOB( ...
                        time-this.bolusHistory.time(b), ...
                        this.opt.insulinPeakTime, ...
                        this.opt.insulinDuration);
                end
            end
            
            % Calculate meal bolus:
            % Bolus covers CHO + correction of high/low glucose - insulin on board.
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
                        correctionBolus = (glucose - targetGlucose) / ISF;
                        infusions.bolusInsulin = round(2*( ...
                            meal.value / carbFactor - ...
                            insulinOnBoard + ...
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
            
            % Calculate correction bolus in case no meal bolus is given.
            if ~this.opt.mealBolus || meal.value == 0
                if this.opt.correctionBolus && ...
                        time - this.lastBolusTime > 1.5 * 60
                    correctionBolusConditions = false;
                    for k = 1:length(this.opt.corrBolusRules)
                        correctionBolusConditions = correctionBolusConditions || ...
                            (glucose >= this.opt.corrBolusRules(k).glucoseThresh && ...
                            this.dGlucoseHistory(:, end) >= this.opt.corrBolusRules(k).dGlucoseThresh);
                    end
                    
                    if correctionBolusConditions
                        corrBolus = (glucose - targetGlucose) / ISF - ...
                            insulinOnBoard;
                        
                        if corrBolus > 0
                            infusions.bolusInsulin = round(2*corrBolus, 1) / 2;
                        end
                    end
                end
            end
            
            if ~isempty(this.opt.bolusCalculatorError.time)
                idx = find(this.opt.bolusCalculatorError.time <= time, 1, 'last');
                if ~isempty(idx)
                    infusions.bolusInsulin = infusions.bolusInsulin * (1 + this.opt.bolusCalculatorError.value(idx));
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
    
    methods (Access = private)
        
        function iob = scalableExpIOB(this, t, tp, td)
            %SCALABLEEXPIOB
            % Calculates the insulin bolus on board using a decay
            % expenontiel. Function taken from
            % https://github.com/ps2/LoopIOB/blob/master/ScalableExp.ipynb
            % Original contributor Dragan Maksimovic (@dm61)
            %
            % Inputs:
            %    - t: Time duration after bolus delivery.
            %    - tp: Time of peak action of insulin.
            %    - td: Time duration of insulin action.
            %
            % For more info on tp and td:
            % http://guidelines.diabetes.ca/cdacpg_resources/Ch12_Table1_Types_of_Insulin_updated_Aug_5.pdf
            %
            
            if t > td
                iob = 0;
            else
                tau = tp * (1 - tp / td) / (1 - 2 * tp / td);
                a = 2 * tau / td;
                S = 1 / (1 - a + (1 + a) * exp(-td/tau));
                iob = 1 - S * (1 - a) * ((t.^2 / (tau * td * (1 - a)) - t / tau - 1) .* exp(-t/tau) + 1);
            end
        end
    end
end
