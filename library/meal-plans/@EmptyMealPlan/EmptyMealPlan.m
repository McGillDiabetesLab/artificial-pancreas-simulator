classdef EmptyMealPlan < MealPlan
    
    methods
        function this = EmptyMealPlan(simulationStartTime, simulationDuration, simulationStepSize, options)
            this@MealPlan(simulationStartTime, simulationDuration, simulationStepSize);
        end
        
        function meal = getMeal(this, time)
            meal.value = zeros(size(time));
            meal.glycemicLoad = zeros(size(time));
            meal.announced = ones(size(time));
        end
    end
    
end
