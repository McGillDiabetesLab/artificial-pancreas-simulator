classdef EmptyMealPlan < MealPlan
    
    methods
        function this = EmptyMealPlan(simulationStartTime, simulationDuration, simulationStepSize, options)
            this@MealPlan(simulationStartTime, simulationDuration, simulationStepSize);
        end
        
        function meal = getMeal(this, time)
            % Use sparse matrices for efficient storage.
            meal.value = zeros(length(time), 1);
            meal.glycemicLoad = zeros(length(time), 1);
            meal.announced = ones(length(time), 1);
        end
    end
    
end
