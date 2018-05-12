classdef RandomMealPlan < MealPlan
    
    properties(GetAccess = public, SetAccess = private)
        meals; % Precomputed meal values and glycemic loads.
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            mealNames = {'breakfast', 'lunch', 'dinner'};
            
            defaultAns = struct();
            defaultAns.plan = cell(3, 5);
            if ~exist('lastOptions', 'var')
                defaultAns.name = className;
                defaultAns.plan(1, :) = {formatTime(7*60, false), formatTime(9*60, false), ...
                    '40', '60', '100'};
                defaultAns.plan(2, :) = {formatTime(12*60, false), formatTime(13*60, false), ...
                    '60', '100', '100'};
                defaultAns.plan(3, :) = {formatTime(17*60, false), formatTime(21*60, false), ...
                    '20', '80', '100'};
                defaultAns.afternoonSnack = true;
                defaultAns.bedtimeSnack = false;
            else
                defaultAns.name = lastOptions.name;
                for mnIdx = 1:numel(mealNames)
                    defaultAns.plan(mnIdx, :) = { ...
                        formatTime(lastOptions.plan.(mealNames{mnIdx}).time(1), false), ...
                        formatTime(lastOptions.plan.(mealNames{mnIdx}).time(end), false), ...
                        num2str(lastOptions.plan.(mealNames{mnIdx}).value(1)), ...
                        num2str(lastOptions.plan.(mealNames{mnIdx}).value(end)), ...
                        num2str(100*lastOptions.plan.(mealNames{mnIdx}).announcedFraction)};
                end
                defaultAns.afternoonSnack = lastOptions.afternoonSnack;
                defaultAns.bedtimeSnack = lastOptions.bedtimeSnack;
            end
            
            dlgTitle = 'Configure Random Meal Plan';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Plan name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200; % Automatically assign the height.
            
            prompt(end+1, :) = {sprintf('\nBreakfast:\nLunch:\nDinner:'), 'plan', []};
            formats(end+1, 1).type = 'table';
            formats(end, 1).format = {'char', 'char', 'char', 'char', 'char'};
            formats(end, 1).items = {'Min Time (DD HH:MM)', 'Max Time (DD HH:MM)', 'Min Value (g)', 'Max Value (g)', 'Announced Percentage (%)'};
            formats(end, 1).size = [575, 77];
            
            prompt(end+1, :) = {'Snack between lunch and dinner.', 'afternoonSnack', []};
            formats(end+1, 1).type = 'check';
            
            prompt(end+1, :) = {'Snack before sleep.', 'bedtimeSnack', []};
            formats(end+1, 1).type = 'check';
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, defaultAns);
            
            options = [];
            if ~cancelled
                options.name = answer.name;
                options.afternoonSnack = answer.afternoonSnack;
                options.bedtimeSnack = answer.bedtimeSnack;
                for mnIdx = 1:numel(mealNames)
                    options.plan.(mealNames{mnIdx}).time = [parseTime(answer.plan{mnIdx, 1}), parseTime(answer.plan{mnIdx, 2})];
                    options.plan.(mealNames{mnIdx}).value = [str2double(answer.plan{mnIdx, 3}), str2double(answer.plan{mnIdx, 4})];
                    if isempty(answer.plan{mnIdx, 5})
                        options.plan.(mealNames{mnIdx}).announcedFraction = 1;
                    else
                        options.plan.(mealNames{mnIdx}).announcedFraction = str2double(answer.plan{mnIdx, 5}) / 100;
                    end
                end
            end
        end
    end
    
    methods
        function this = RandomMealPlan(simulationStartTime, simulationDuration, simulationStepSize, options)
            this@MealPlan(simulationStartTime, simulationDuration, simulationStepSize);
            
            % Parse options.
            if exist('options', 'var') && isfield(options, 'name')
                this.name = options.name;
            end
            
            if exist('options', 'var') && isfield(options, 'plan')
                plan = options.plan;
            else
                plan.breakfast.time = [7, 9] * 60;
                plan.breakfast.value = [40, 60];
                plan.breakfast.announcedFraction = 1;
                
                plan.lunch.time = [12, 13] * 60;
                plan.lunch.value = [60, 100];
                plan.lunch.announcedFraction = 1;
                
                plan.dinner.time = [17, 21] * 60;
                plan.dinner.value = [20, 80];
                plan.dinner.announcedFraction = 1;
            end
            
            if exist('options', 'var') && isfield(options, 'afternoonSnack')
                afternoonSnack = options.afternoonSnack;
            else
                afternoonSnack = true;
            end
            
            if exist('options', 'var') && isfield(options, 'bedtimeSnack')
                bedtimeSnack = options.bedtimeSnack;
            else
                bedtimeSnack = false;
            end
            
            if exist('options', 'var') && isfield(options, 'RNGSeed') && options.RNGSeed > 0
                rng(options.RNGSeed);
            end
            
            % Compute number of steps.
            numDays = ceil((simulationStartTime + simulationDuration)/(24 * 60)) + 1;
            numSteps = ceil(numDays*24*60/simulationStepSize);
            
            % Use sparse matrices for efficient storage.
            this.meals.values = sparse(numSteps, 1);
            this.meals.glycemicLoads = sparse(numSteps, 1);
            this.meals.announced = sparse(numSteps, 1);
            
            % Fill meals from plan.
            for day = 1:numDays
                % Breakfast.
                breakfastIndex = round(((day - 1) * 24 * 60 + plan.breakfast.time(1) + diff(plan.breakfast.time) * rand(1))/this.simulationStepSize) + 1;
                if simulationStartTime >= plan.breakfast.time(1) && ...
                        simulationStartTime <= plan.breakfast.time(end) && ...
                        breakfastIndex < floor(simulationStartTime/simulationStepSize) + 1
                    breakfastIndex = floor(simulationStartTime/simulationStepSize) + 1;
                end
                this.meals.values(breakfastIndex) = round(plan.breakfast.value(1)+diff(plan.breakfast.value)*rand(1));
                this.meals.glycemicLoads(breakfastIndex) = 1;
                this.meals.announced(breakfastIndex) = plan.breakfast.announcedFraction > rand(1);
                
                % Lunch.
                lunchIndex = round(((day - 1) * 24 * 60 + plan.lunch.time(1) + diff(plan.lunch.time) * rand(1))/this.simulationStepSize) + 1;
                if simulationStartTime >= plan.lunch.time(1) && ...
                        simulationStartTime <= plan.lunch.time(end) && ...
                        lunchIndex < floor(simulationStartTime/simulationStepSize) + 1
                    lunchIndex = floor(simulationStartTime/simulationStepSize) + 1;
                end
                this.meals.values(lunchIndex) = round(plan.lunch.value(1)+diff(plan.lunch.value)*rand(1));
                this.meals.glycemicLoads(lunchIndex) = 1;
                this.meals.announced(lunchIndex) = plan.lunch.announcedFraction > rand(1);
                
                % Dinner.
                dinnerIndex = round(((day - 1) * 24 * 60 + plan.dinner.time(1) + diff(plan.dinner.time) * rand(1))/this.simulationStepSize) + 1;
                if simulationStartTime >= plan.dinner.time(1) && ...
                        simulationStartTime <= plan.dinner.time(end) && ...
                        dinnerIndex < floor(simulationStartTime/simulationStepSize) + 1
                    dinnerIndex = floor(simulationStartTime/simulationStepSize) + 1;
                end
                this.meals.values(dinnerIndex) = round(plan.dinner.value(1)+diff(plan.dinner.value)*rand(1));
                this.meals.glycemicLoads(dinnerIndex) = 1;
                this.meals.announced(dinnerIndex) = plan.dinner.announcedFraction > rand(1);
                
                % Afternoon snack.
                if afternoonSnack
                    if dinnerIndex - lunchIndex - 2 * round(120/this.simulationStepSize) > 0
                        snackIndex = lunchIndex + randi(dinnerIndex-lunchIndex-2*round(120/this.simulationStepSize)+1) + round(120/this.simulationStepSize);
                        snack = round(30*rand(1));
                        if snack > 9 && snackIndex < numel(this.meals.values)
                            this.meals.values(snackIndex) = this.meals.values(snackIndex) + snack;
                            this.meals.glycemicLoads(snackIndex) = 1;
                            this.meals.announced(snackIndex) = 1;
                        end
                    end
                end
                
                % Bedtime snack.
                if bedtimeSnack
                    snackIndex = dinnerIndex + randi(round(120/this.simulationStepSize)+1) + round(60/this.simulationStepSize);
                    snack = round(30*rand(1));
                    if snack > 9 && snackIndex < numel(this.meals.values)
                        this.meals.values(snackIndex) = this.meals.values(snackIndex) + snack;
                        this.meals.glycemicLoads(snackIndex) = 1;
                        this.meals.announced(snackIndex) = 1;
                    end
                end
            end
        end
        
        function meal = getMeal(this, time)
            index = round(time/this.simulationStepSize) + 1;
            
            meal.value = this.meals.values(index);
            meal.glycemicLoad = this.meals.glycemicLoads(index);
            meal.announced = this.meals.announced(index);
        end
    end
    
end
