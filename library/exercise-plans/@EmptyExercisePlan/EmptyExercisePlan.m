classdef EmptyExercisePlan < ExercisePlan
    
    methods
        function this = EmptyExercisePlan(simulationStartTime, simulationDuration, simulationStepSize, options)
            this@ExercisePlan(simulationStartTime, simulationDuration, simulationStepSize);
        end
        
        function exercise = getExercise(this, time)
            exercise.duration = zeros(size(time));
            exercise.intensity = zeros(size(time));
            exercise.type = zeros(size(time));
            exercise.announced = ones(size(time));
        end
    end
    
end
