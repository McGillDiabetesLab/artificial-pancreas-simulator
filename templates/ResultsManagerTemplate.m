classdef ResultsManagerTemplate < ResultsManager

    properties (GetAccess = public, SetAccess = private)
        % Declare any internal variables used by the class here.
        measurementTimes % Example: cell array of glucose measurement times.
        measurements % Example: cell array of glucose measurements.
        infusionTimes % Example: cell array of infusion times.
        infusions % Example: cell array of infusions.
    end

    methods (Static)
        function displayResults(resultsManagers)
            % Write your code to plot or log the results at the end of the simulation here.
            % Example: plot the measurements for every results manager individually.
            for i = 1:numel(resultsManagers)
                plot(cell2mat(resultsManagers{i}.measurementTimes), cell2mat(resultsManagers{i}.measurements));
            end
        end
    end

    methods
        function this = ResultsManagerTemplate(simulationDuration, simulationStartTime, simulationStepSize, patient, controller)
            % Default constructor

            % Calls the base class constructor to initialize the base object. This is required.
            this@ResultsManager(simulationDuration, simulationStartTime, simulationStepSize, patient, controller);

            % Write your code to initialize the results manager here.
            % Example: initialize the internal variables to empty cell arrays.
            this.measurementTimes = {};
            this.measurements = {};
            this.infusionTimes = {};
            this.infusions = {};
        end

        function addGlucoseMeasurement(this, currentTime, measurement)
            this.measurementTimes{end+1} = currentTime; % Example: add the current time to the glucose measurement times.
            this.measurements{end+1} = measurement; % Example: add the current measurement to the glucose measurements.
            % Write your code to update the plot during the simulation here if desired.

        end

        function addInfusions(this, currentTime, infusions)
            this.infusionTimes{end+1} = currentTime; % Example: add the current time to the infusion times.
            this.infusions{end+1} = infusions; % Example: add the current infusions to the infusions.
            % Write your code to update the plot during the simulation here if desired.

        end
    end

    methods (Access = private)
        % Define any additional internal functions here. These functions
        % cannot be accessed from outside of this class.

    end

end

