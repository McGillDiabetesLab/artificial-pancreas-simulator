classdef PIDController < InfusionController
    %PIDCONTROLLER  Proportional-Integral-Derivative controller.
    %   For more details, see https://en.wikipedia.org/wiki/PID_controller.
    
    properties(GetAccess = public, SetAccess = immutable)
        glucoseHistorySize = 10;
    end
    
    properties(GetAccess = public, SetAccess = private)
        opt; % Options configured by the user.
        
        glucoseHistory;
        totalGlucoseError;
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            if ~exist('lastOptions', 'var')
                lastOptions = struct();
                lastOptions.name = className;
                lastOptions.glucoseTarget = 5.5; % mmol/L.
                lastOptions.kP = 1e-2;
                lastOptions.kI = 1e-5;
                lastOptions.kD = 1e1;
                lastOptions.filterNoise = true;
            end
            
            dlgTitle = 'Configure PID Controller';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Controller name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200;
            
            prompt(end+1, :) = {'Glucose target:', 'glucoseTarget', 'mmol/L'};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 50;
            
            prompt(end+1, :) = {'Proportional:', 'kP', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 100;
            
            prompt(end+1, :) = {'       Integral:', 'kI', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 100;
            
            prompt(end+1, :) = {'   Derivative:', 'kD', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 100;
            
            prompt(end+1, :) = {'Filter sensor noise.', 'filterNoise', []};
            formats(end+1, 1).type = 'check';
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, lastOptions);
            
            options = [];
            if ~cancelled
                options = answer;
            end
        end
    end
    
    methods
        function this = PIDController(simulationStartTime, simulationDuration, simulationStepSize, patient, options)
            this@InfusionController(simulationStartTime, simulationDuration, simulationStepSize, patient);
            
            % Parse options.
            this.opt = struct();
            this.opt.name = this.name;
            this.opt.glucoseTarget = 5.5; % mmol/L.
            this.opt.kP = 1e-2;
            this.opt.kI = 1e-5;
            this.opt.kD = 1e1;
            this.opt.filterNoise = true;
            
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
            this.totalGlucoseError = 0.0;
        end
        
        function infusions = getInfusions(this, time)
            glucose = this.patient.getGlucoseMeasurement();
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
            
            if ~isnan(glucose)
                filteredGlucose = glucose;
                if this.opt.filterNoise
                    % We use an IIR filter with the transfer function
                    % H(z) = (1-alpha)^2 / (1 - alpha z^(-1) - alpha (1 - alpha) z^(-2))
                    % where alpha is a tuning parameter.
                    % For more details, see
                    % https://en.wikipedia.org/wiki/Infinite_impulse_response.
                    if all(~isnan(this.glucoseHistory(:, end-1:end)))
                        alpha = 0.5;
                        filteredGlucose = ((1 - alpha)^2) * glucose + alpha * ...
                            (this.glucoseHistory(:, end) + (1 - alpha) * this.glucoseHistory(:, end-1));
                    end
                end
                
                % For the glucose derivative (rate of change), we use the
                % second order backward finite difference.
                % For more details, see
                % https://en.wikipedia.org/wiki/Finite_difference_coefficient.
                if all(~isnan(this.glucoseHistory(:, end-1:end)))
                    dGlucose = (3 * filteredGlucose - 4 * this.glucoseHistory(:, end) + ...
                        this.glucoseHistory(:, end-1)) / (2 * this.simulationStepSize);
                else
                    dGlucose = 0;
                end
                
                Upid = (filteredGlucose - this.opt.glucoseTarget) * this.opt.kP + ...
                    dGlucose * this.opt.kD + ...
                    this.totalGlucoseError * this.opt.kI;
                Upid = max(min(Upid, 2*Ub), -Ub);
                
                infusions.basalInsulin = Ub + Upid;
                
                this.totalGlucoseError = this.totalGlucoseError + (filteredGlucose - this.opt.glucoseTarget);
            end
            
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
            
            % Update state.
            this.glucoseHistory(:, 1:end-1) = this.glucoseHistory(:, 2:end);
            this.glucoseHistory(:, end) = filteredGlucose;
        end
        
        function setInfusions(this, time, infusions)
            % Nothing to do since we don't store infusions history.
        end
    end
    
end
