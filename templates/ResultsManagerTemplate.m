classdef ResultsManagerTemplate < ResultsManager
    
    properties(GetAccess = public, SetAccess = private)
        % Declare any internal variables used by the class here.
    end
    
    methods(Static)
        function displayResults(resultsManagers)
            % Write your code to plot or log the results at the end of the simulation here.
            % Example: plot the measurements for every results manager individually.
            for i = 1:numel(resultsManagers)
                plot(cell2mat(resultsManagers{i}.measurementTimes), cell2mat(resultsManagers{i}.measurements));
            end
        end
    end
    
    methods
        function this = ResultsManagerTemplate(simulationDuration, simulationStartTime, simulationStepSize, patient, primaryController, secondaryController)
            % Default constructor
            
            % Calls the base class constructor to initialize the base object. This is required.
            this@ResultsManager(simulationStartTime, simulationDuration, simulationStepSize, patient, primaryController, secondaryController);
        end
    end
    
    methods(Access = private)
        % Define any additional internal functions here. These functions
        % cannot be accessed from outside of this class.
        
    end
    
end
