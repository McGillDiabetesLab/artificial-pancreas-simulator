classdef BasalBolusTherapy < InfusionController
    %BASALBOLUSTHERAPY  Open loop therapy with a pump.
    
    properties(GetAccess = public, SetAccess = immutable)
        glucoseHistorySize = 100;
    end
    
    properties(GetAccess = public, SetAccess = private)
        opt; % Options configured by the user.
        
        glucoseHistory;
        filteredGlucoseHistory;
        dGlucoseHistory;
        
        pumpShutOff;
        lastBolusTime;
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            if ~exist('lastOptions', 'var')
                lastOptions = struct();
                lastOptions.name = className;
                lastOptions.correctionBolus = false;
                lastOptions.dGlucoseHyperBolusThresh = 0.05;
                lastOptions.hypoPumpShutoff = false;
                lastOptions.dGlucosePumpShutoffThresh = 0.03;
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
            formats(end, 1).size = 200;
            
            prompt(end+1, :) = {'Provide correction boluses...', 'correctionBolus', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).callback = @toggleOptionValue;
            formats(end, 1).size = 140;
            
            prompt(end+1, :) = {'at a glucose rate of change threshold of', 'dGlucoseHyperBolusThresh', 'mmol / (L min)'};
            formats(end, 2).type = 'edit';
            formats(end, 2).format = 'float';
            if lastOptions.correctionBolus
                formats(end, 2).enable = 'on';
            else
                formats(end, 2).enable = 'off';
            end
            formats(end, 2).size = 70;
            
            prompt(end+1, :) = {'Automatically shut off pump when hypo...', 'hypoPumpShutoff', []};
            formats(end+1, 1).type = 'check';
            formats(end, 1).callback = @toggleOptionValue;
            formats(end, 1).size = 140;
            
            prompt(end+1, :) = {'at a glucose rate of change threshold of', 'dGlucosePumpShutoffThresh', 'mmol / (L min)'};
            formats(end, 2).type = 'edit';
            formats(end, 2).format = 'float';
            if lastOptions.hypoPumpShutoff
                formats(end, 2).enable = 'on';
            else
                formats(end, 2).enable = 'off';
            end
            formats(end, 2).size = 70;
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, lastOptions);
            
            options = [];
            if ~cancelled
                options = answer;
            end
        end
    end
    
    methods
        function this = BasalBolusTherapy(simulationStartTime, simulationDuration, simulationStepSize, patient, options)
            this@InfusionController(simulationStartTime, simulationDuration, simulationStepSize, patient);
            
            % Parse options.
            this.opt = struct();
            this.opt.name = this.name;
            this.opt.correctionBolus = false;
            this.opt.dGlucoseHyperBolusThresh = 0.05;
            this.opt.hypoPumpShutoff = false;
            this.opt.dGlucosePumpShutoffThresh = 0.03;
            
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
            
            this.pumpShutOff = false;
            this.lastBolusTime = 0.0;
        end
        
        function infusions = getInfusions(this, time)
            glucose = this.patient.getGlucoseMeasurement();
            this.glucoseHistory(:, 1:end-1) = this.glucoseHistory(:, 2:end);
            this.glucoseHistory(:, end) = glucose;
            
            prop = this.patient.getProperties();
            
            % Get basal.
            if isfield(prop, 'pumpBasals')
                idx = find(prop.pumpBasals.time <= mod(time, 24*60), 1, 'last');
                if ~isempty(idx)
                    Ub = prop.pumpBasals.value(idx);
                else
                    Ub = prop.pumpBasals.value(end);
                end
            else % Use a default basal.
                Ub = 1.0; % U/h.
            end
            infusions.basalInsulin = Ub;
            
            % Get bolus.
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
                infusions.bolusInsulin = round(meal.value/carbFactor, 1);
            else
                infusions.bolusInsulin = 0;
            end
            
            % Correct basal and bolus if options are set.
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
                
                if this.opt.hypoPumpShutoff
                    if this.pumpShutOff && ...
                            ((filteredGlucose > 3.9 && ...
                            mean(this.dGlucoseHistory(end-1:end)) > abs(this.opt.dGlucosePumpShutoffThresh)) || ...
                            filteredGlucose > 5.5)
                        this.pumpShutOff = false;
                    end
                    
                    if this.pumpShutOff || ...
                            ((filteredGlucose < 5.5 && ...
                            mean(this.dGlucoseHistory(end-1:end)) < -abs(this.opt.dGlucosePumpShutoffThresh)) || ...
                            filteredGlucose < 3.9)
                        infusions.basalInsulin = 0;
                        this.pumpShutOff = true;
                    end
                end
                
                if this.opt.correctionBolus
                    if time - this.lastBolusTime > 2.5 * 60 % Last bolus has been provided some time ago.
                        bolusCorrectionConditions = ...
                            (filteredGlucose > 10 && mean(this.dGlucoseHistory(end-2:end)) > abs(this.opt.dGlucoseHyperBolusThresh)) || ...
                            (filteredGlucose > 12 && mean(this.dGlucoseHistory(end-1:end)) > 0.5 * abs(this.opt.dGlucoseHyperBolusThresh)) || ...
                            (filteredGlucose > 14 && this.dGlucoseHistory(end) > 0);
                        if bolusCorrectionConditions
                            corrBolus = 0;
                            if isfield(prop, 'TDD')
                                corrBolus = round(2*(filteredGlucose - 7.0)/(100 / prop.TDD), 1) / 2;
                            end
                            if isfield(prop, 'carbFactors')
                                idx = find(prop.carbFactors.time <= mod(time, 24*60), 1, 'last');
                                if ~isempty(idx)
                                    carbFactor = prop.carbFactors.value(idx);
                                else
                                    carbFactor = prop.carbFactors.value(end);
                                end
                                corrBolus = min(corrBolus, round(2*40/carbFactor)/2);
                            end
                            if corrBolus >= 1.0
                                infusions.bolusInsulin = infusions.bolusInsulin + corrBolus;
                            end
                        end
                    end
                end
            else
                this.filteredGlucoseHistory(:, 1:end-1) = this.filteredGlucoseHistory(:, 2:end);
                this.filteredGlucoseHistory(:, end) = glucose;
                this.dGlucoseHistory(:, 1:end-1) = this.dGlucoseHistory(:, 2:end);
                this.dGlucoseHistory(:, end) = 0;
            end
        end
        
        function setInfusions(this, time, infusions)
            if infusions.bolusInsulin > 0
                this.lastBolusTime = time;
            end
        end
    end
    
end
