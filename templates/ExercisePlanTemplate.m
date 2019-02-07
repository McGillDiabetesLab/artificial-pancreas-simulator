classdef ExercisePlanTemplate < ExercisePlan

    properties (GetAccess = public, SetAccess = private)
        % Declare any internal variables used by the class here.

    end

    methods
        function this = ExercisePlanTemplate(simulationDuration, simulationStartTime, simulationStepSize, options)
            % Default constructor

            % Calls the base class constructor to initialize the base object. This is required.
            this@ExercisePlan(simulationDuration, simulationStartTime, simulationStepSize);

            % Write your code to initialize the exercise plan here.

        end

        function exercise = getExercise(this, currentTime)
            % Define how other entities (such as the virtual patient) get the current exercise here.
            exercise.startTime = currentTime; % Example: set the start time.
            exercise.endTime = currentTime; % Example: set the end time.
            exercise.intensity = 0; % Example: set the exercise intensity.
            exercise.type = 0; % Example: set the exercise type.
            exercise.announced = 0; % Example: set if the exercise is announced to the controller.
        end
    end

    methods (Access = private)
        % Define any additional internal functions here. These functions
        % cannot be accessed from outside of this class.

    end

end

