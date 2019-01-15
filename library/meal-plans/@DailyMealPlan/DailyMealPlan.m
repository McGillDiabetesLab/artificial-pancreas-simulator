classdef DailyMealPlan < MealPlan
    
    properties(GetAccess = public, SetAccess = private)
        meals; % Precomputed meal values and glycemic loads.
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            defaultAns = struct();
            defaultAns.mealTable = cell(50, 6);
            if ~exist('lastOptions', 'var')
                defaultAns.name = className;
                defaultAns.mealTable(1, :) = {true, 'Breakfast', formatTime(8*60, false), '40', '25', '100'};
                defaultAns.mealTable(2, :) = {true, 'Lunch', formatTime(12*60, false), '80', '15', '100'};
                defaultAns.mealTable(3, :) = {true, 'Dinner', formatTime(18*60, false), '60', '15', '100'};
                defaultAns.mealTable(4, :) = {true, 'Snack', formatTime(22*60, false), '30', '5', '100'};
            else
                defaultAns.name = lastOptions.name;
                for i = 1:numel(lastOptions.meals)
                    defaultAns.mealTable(i, :) = { ...
                        lastOptions.meals(i).repeat, ...
                        lastOptions.meals(i).description, ...
                        formatTime(lastOptions.meals(i).time, false), ...
                        num2str(lastOptions.meals(i).value), ...
                        num2str(lastOptions.meals(i).glycemicLoad), ...
                        num2str(100*lastOptions.meals(i).announcedFraction)};
                end
            end
            
            dlgTitle = 'Configure Daily Meal Plan';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Plan name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200; % Automatically assign the height.
            
            prompt(end+1, :) = {'', 'mealTable', []};
            formats(end+1, 1).type = 'table';
            formats(end, 1).format = {'logical', 'char', 'char', 'char', 'char', 'char'};
            formats(end, 1).items = {'Repeat', 'Description', 'Time (DD HH:MM)', 'Value (g)', 'Glycemic Load', 'Announced Percentage (%)'};
            formats(end, 1).size = [552, 200];
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, defaultAns);
            
            options = [];
            if ~cancelled
                options.name = answer.name;
                
                for i = 1:size(answer.mealTable, 1)
                    if ~isempty(answer.mealTable{i, 3})
                        if isempty(answer.mealTable{i, 1})
                            options.meals(i).repeat = false;
                        else
                            options.meals(i).repeat = answer.mealTable{i, 1};
                        end
                        options.meals(i).description = answer.mealTable{i, 2};
                        options.meals(i).time = parseTime(answer.mealTable{i, 3});
                        options.meals(i).value = str2double(answer.mealTable{i, 4});
                        if isempty(answer.mealTable{i, 5})
                            options.meals(i).glycemicLoad = 1;
                        else
                            options.meals(i).glycemicLoad = str2double(answer.mealTable{i, 5});
                        end
                        if isempty(answer.mealTable{i, 6})
                            options.meals(i).announcedFraction = 1;
                        else
                            options.meals(i).announcedFraction = str2double(answer.mealTable{i, 6}) / 100;
                        end
                    end
                end
            end
        end
    end
    
    methods
        function this = DailyMealPlan(simulationStartTime, simulationDuration, simulationStepSize, options)
            this@MealPlan(simulationStartTime, simulationDuration, simulationStepSize);
            
            % Parse options.
            if exist('options', 'var') && isfield(options, 'name')
                this.name = options.name;
            end
            
            if exist('options', 'var') && isfield(options, 'meals')
                meals = options.meals;
            else
                mealTable = table( ...
                    logical([1; 1; 1; 1]), ...
                    [8; 12; 18; 22]*60, ...
                    [40; 80; 60; 30], ...
                    [25; 15; 15; 5], ...
                    [1; 1; 1; 1], ...
                    'VariableNames', {'repeat', 'time', 'value', 'glycemicLoad', 'announcedFraction'});
                meals = table2struct(mealTable);
            end
            
            % Compute number of steps.
            numDays = ceil((simulationStartTime + simulationDuration)/(24 * 60)) + 1;
            numSteps = ceil(numDays*24*60/simulationStepSize);
            
            % Use sparse matrices for efficient storage.
            this.meals.values = sparse(numSteps, 1);
            this.meals.glycemicLoads = sparse(numSteps, 1);
            this.meals.announced = sparse(numSteps, 1);
            
            % Fill meals from meal table.
            for i = 1:numel(meals)
                index = floor(meals(i).time/this.simulationStepSize) + 1;
                
                this.meals.values(index) = meals(i).value;
                this.meals.glycemicLoads(index) = meals(i).glycemicLoad;
                this.meals.announced(index) = meals(i).announcedFraction > rand(1);
                
                if meals(i).repeat
                    day = 1;
                    index = floor((meals(i).time + day * 24 * 60)/this.simulationStepSize) + 1;
                    while index <= numSteps
                        this.meals.values(index) = meals(i).value;
                        this.meals.glycemicLoads(index) = meals(i).glycemicLoad;
                        this.meals.announced(index) = meals(i).announcedFraction > rand(1);
                        day = day + 1;
                        index = floor((meals(i).time + day * 24 * 60)/this.simulationStepSize) + 1;
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
