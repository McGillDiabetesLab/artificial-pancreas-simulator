classdef PIDController < InfusionController
    %PIDCONTROLLER  Proportional-Integral-Derivative controller.
    %   For more details, see
    %   * https://en.wikipedia.org/wiki/PID_controller.
    %   * Astrom, Karl Johan, and Richard M. Murray. Feedback systems: an
    %   introduction for scientists and engineers. Princeton university
    %   press, 2010. Chapter 10.
    
    properties(GetAccess = public, SetAccess = immutable)
        glucoseHistorySize = 10;
    end
    
    properties(GetAccess = public, SetAccess = private)
        opt; % Options configured by the user.
        
        glucoseHistory;
        lastIntegralCoeff;
        lastDerivativeCoeff;
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            if ~exist('lastOptions', 'var')
                lastOptions = struct();
                lastOptions.name = className;
                lastOptions.glucoseTarget = 7.0; % mmol/L.
                lastOptions.kP = 2e-2;
                lastOptions.kI = 5e-5;
                lastOptions.kD = 5;
                lastOptions.nD = 5e-2;
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
            
            prompt(end+1, :) = {'      Proportional:', 'kP', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 100;
            
            prompt(end+1, :) = {'             Integral:', 'kI', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 100;
            
            prompt(end+1, :) = {'         Derivative:', 'kD', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 100;
            
            prompt(end+1, :) = {'Filter coefficient:', 'nD', '(inf for no filtering)'};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'float';
            formats(end, 1).size = 100;
            
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
            this.opt.glucoseTarget = 7.0; % mmol/L.
            this.opt.kP = 2e-2;
            this.opt.kI = 5e-5;
            this.opt.kD = 5;
            this.opt.nD = 5e-2;
            
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
            this.lastIntegralCoeff = 0.0;
            this.lastDerivativeCoeff = 0.0;
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
            
            if ~isnan(glucose)
                proportionalCoeff = this.opt.kP * (glucose - this.opt.glucoseTarget);
                integralCoeff = this.lastIntegralCoeff;
                this.lastIntegralCoeff = this.lastIntegralCoeff + this.opt.kI * this.simulationStepSize * (glucose - this.opt.glucoseTarget);
                if ~isnan(this.glucoseHistory(:, end-1))
                    derivativeCoeff = (1 / (1 + this.simulationStepSize * this.opt.nD)) * this.lastDerivativeCoeff + ...
                        (this.opt.kD / this.simulationStepSize / (1 + 1 / (this.opt.nD * this.simulationStepSize))) * (glucose - this.glucoseHistory(:, end-1));
                else
                    derivativeCoeff = 0;
                end
                this.lastDerivativeCoeff = derivativeCoeff;
                Upid = proportionalCoeff + integralCoeff + derivativeCoeff;
                
                Upid = max(min(Upid, 5.0*Ub), -Ub);
            else
                Upid = 0.0;
            end
            
            infusions.basalInsulin = Ub + Upid;
            
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
        end
        
        function setInfusions(this, time, infusions)
            % Nothing to do since we don't store infusions history.
        end
    end
    
end
