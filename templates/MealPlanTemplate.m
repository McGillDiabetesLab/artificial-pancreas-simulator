classdef MealPlanTemplate < MealPlan

    properties (GetAccess = public, SetAccess = private)
        % Declare any internal variables used by the class here.

    end

    methods
        function this = MealPlanTemplate(simulationDuration, simulationStartTime, simulationStepSize)
            % Default constructor

            % Calls the base class constructor to initialize the base object. This is required.
            this@MealPlan(simulationDuration, simulationStartTime, simulationStepSize);

            % Write your code to initialize the meal plan here.

        end

        function meal = getMeal(this, currentTime)
            % Define how other entities (such as the virtual patient) get the current meal here.
            meal.value = 0; % Example: set the meal value.
            meal.glycemicLoad = 0; % Example: set the meal glycemic load.
        end
    end

    methods (Access = private)
        % Define any additional internal functions here. These functions
        % cannot be accessed from outside of this class.

    end

end

