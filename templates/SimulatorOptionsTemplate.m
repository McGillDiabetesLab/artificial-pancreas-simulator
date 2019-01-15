classdef SimulatorOptionsTemplate < SimulatorOptions

    methods
        function this = SimulatorOptionsTemplate()
            this.simulationDuration =  24*60; % minutes
            this.simulationStartTime = 8*60; % minutes
            this.simulationStepSize = 10; % minutes
            this.parallelExecution = true;
            this.virtualPatients = { ...
                {'VirtualPatientTemplate', 0, 'MealPlanTemplate', 'ExercisePlanTemplate', 'InfusionControllerTemplate'}, ...
                };
            this.resultsManager = 'ResultsManagerTemplate';
        end
    end

end

