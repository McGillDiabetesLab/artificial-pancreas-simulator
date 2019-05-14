classdef RandomMealPlan < MealPlan
    
    properties(GetAccess = public, SetAccess = private)
        meals; % Precomputed meal values and glycemic loads.
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            mealNames = {'breakfast', 'snackMorning', 'lunch', 'snackAfternoon', 'dinner', 'snackNight'};
            
            defaultAns = struct();
            defaultAns.plan = cell(6, 7);
            if ~exist('lastOptions', 'var')
                defaultAns.name = className;
                defaultAns.plan(1, :) = {true, formatTime(7*60, false), formatTime(9*60, false), '40', '60', '1', '100'};
                defaultAns.plan(2, :) = {false, '', '', '', '', '', ''};
                defaultAns.plan(3, :) = {true, formatTime(12*60, false), formatTime(13*60, false), '60', '100', '1', '100'};
                defaultAns.plan(4, :) = {false, '', '', '', '', '', ''};
                defaultAns.plan(5, :) = {true, formatTime(17*60, false), formatTime(21*60, false), '20', '80', '1', '100'};
                defaultAns.plan(6, :) = {false, '', '', '', '', '', ''};
            else
                defaultAns.name = lastOptions.name;
                for mnIdx = 1:numel(mealNames)
                    if lastOptions.plan.(mealNames{mnIdx}).enabled
                        defaultAns.plan(mnIdx, :) = { ...
                            true, ...
                            formatTime(lastOptions.plan.(mealNames{mnIdx}).time(1), false), ...
                            formatTime(lastOptions.plan.(mealNames{mnIdx}).time(end), false), ...
                            num2str(lastOptions.plan.(mealNames{mnIdx}).value(1)), ...
                            num2str(lastOptions.plan.(mealNames{mnIdx}).value(end)), ...
                            num2str(lastOptions.plan.(mealNames{mnIdx}).glycemicLoad), ...
                            num2str(100*lastOptions.plan.(mealNames{mnIdx}).announcedFraction)};
                    else
                        defaultAns.plan(mnIdx, :) = {false, '', '', '', '', '', ''};
                    end
                end
            end
            
            colorText = @(color, text) ['<html><table border=0 width=400 bgcolor=', color, '><TR><TD>', text, '</TD></TR> </table></html>'];
            
            function txt = extarctTextFromHTML(htmlTxt)
                if contains(string(htmlTxt), 'html')
                    txtStart = strfind(htmlTxt, '<TD>') + 4;
                    txtEnd = strfind(htmlTxt, '</TD>') - 1;
                    txt = htmlTxt(txtStart:txtEnd);
                else
                    txt = htmlTxt;
                end
            end
            
            function updatePlanTable(~, ~, handles, ~)
                set(handles(2, 1), 'RowName', {'Breakfast', 'Morning Snack', 'Lunch', 'Afternoon Snack', 'Dinner', 'Bedtime Snack'});
                
                data = get(handles(2, 1), 'Data');
                for i = 1:length(data(:, 1))
                    if ~cell2mat(data(i, 1))
                        data(i, 2:end) = cellfun(@(s)colorText('#2F4F4F', extarctTextFromHTML(s)), data(i, 2:end), 'UniformOutput', 0);
                    else
                        data(i, 2:end) = cellfun(@(s)colorText('#FFFFFF', extarctTextFromHTML(s)), data(i, 2:end), 'UniformOutput', 0);
                    end
                end
                set(handles(2, 1), 'Data', data);
            end
            
            dlgTitle = 'Configure Random Meal Plan';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Plan name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200; % Automatically assign the height.
            
            prompt(end+1, :) = {'Plan:', 'plan', []};
            formats(end+1, 1).type = 'table';
            formats(end, 1).format = {'logical', 'char', 'char', 'char', 'char', 'char', 'char'};
            formats(end, 1).items = {'Enable', 'Min Time (DD HH:MM)', 'Max Time (DD HH:MM)', 'Min Value (g)', 'Max Value (g)', 'Glycemic Load', 'Announced Percentage (%)'};
            formats(end, 1).size = [590, 150];
            formats(end, 1).callback = @updatePlanTable;
            
            inputsdlgOpt.CreateFcn = @updatePlanTable;
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, defaultAns, inputsdlgOpt);
            
            options = [];
            if ~cancelled
                options.name = answer.name;
                for mnIdx = 1:numel(mealNames)
                    options.plan.(mealNames{mnIdx}) = struct('enabled', false, 'time', [], 'value', [], 'glycemicLoad', 1, 'announcedFraction', 0);
                    if answer.plan{mnIdx, 1} %enabled ?
                        options.plan.(mealNames{mnIdx}).enabled = true;
                        rowPlan = cellfun(@(s)extarctTextFromHTML(s), answer.plan(mnIdx, 2:end), 'UniformOutput', false);
                        options.plan.(mealNames{mnIdx}).time = [parseTime(rowPlan{1}), parseTime(rowPlan{2})];
                        options.plan.(mealNames{mnIdx}).value = [str2double(rowPlan{3}), str2double(rowPlan{4})];
                        options.plan.(mealNames{mnIdx}).glycemicLoad = str2double(rowPlan{5});
                        if isempty(rowPlan{5})
                            options.plan.(mealNames{mnIdx}).announcedFraction = 1;
                        else
                            options.plan.(mealNames{mnIdx}).announcedFraction = str2double(rowPlan{6}) / 100;
                        end
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
            
            if exist('options', 'var') && isfield(options, 'dailyCarbsMax')
                dailyCarbsMax = options.dailyCarbsMax;
            else
                dailyCarbsMax = 400;
            end
            
            if exist('options', 'var') && isfield(options, 'dailyCarbsMin')
                dailyCarbsMin = options.dailyCarbsMin;
            else
                dailyCarbsMin = 40;
            end
            
            if exist('options', 'var') && isfield(options, 'RNGSeed')
                rng(options.RNGSeed);
            end
            
            if exist('options', 'var') && isfield(options, 'plan')
                plan = options.plan;
            else
                plan.breakfast = struct('enabled', true, ...
                    'time', [7, 9]*60, ...
                    'value', [40, 60], ...
                    'glycemicLoad', 1, ...
                    'announcedFraction', 1);
                
                plan.snackMorning = struct('enabled', false, ...
                    'time', [], ...
                    'value', [], ...
                    'glycemicLoad', 1, ...
                    'announcedFraction', 0);
                
                plan.lunch = struct('enabled', true, ...
                    'time', [12, 13]*60, ...
                    'value', [60, 100], ...
                    'glycemicLoad', 1, ...
                    'announcedFraction', 1);
                
                plan.snackAfternoon = struct('enabled', false, ...
                    'time', [], ...
                    'value', [], ...
                    'glycemicLoad', 1, ...
                    'announcedFraction', 0);
                
                plan.dinner = struct('enabled', true, ...
                    'time', [17, 21]*60, ...
                    'value', [30, 70], ...
                    'glycemicLoad', 1, ...
                    'announcedFraction', 1);
                
                plan.snackNight = struct('enabled', false, ...
                    'time', [], ...
                    'value', [], ...
                    'glycemicLoad', 1, ...
                    'announcedFraction', 0);
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
            mealNames = {'breakfast', 'snackMorning', 'lunch', 'snackAfternoon', 'dinner', 'snackNight'};
            for day = 1:numDays
                totalCarbs = -1;
                iter = 0;
                while iter < 100 && (totalCarbs < dailyCarbsMin || totalCarbs > dailyCarbsMax)
                    iter = iter + 1;
                    totalCarbs = 0;
                    meals_ = this.meals;
                    for mnIdx = 1:numel(mealNames)
                        if plan.(mealNames{mnIdx}).enabled
                            Index = round(((day - 1) * 24 * 60 + plan.(mealNames{mnIdx}).time(1) + diff(plan.(mealNames{mnIdx}).time) * rand(1))/this.simulationStepSize) + 1;
                            if simulationStartTime >= plan.(mealNames{mnIdx}).time(1) && ...
                                    simulationStartTime <= plan.(mealNames{mnIdx}).time(end) && ...
                                    Index < floor(simulationStartTime/simulationStepSize) + 1
                                Index = floor(simulationStartTime/simulationStepSize) + 1;
                            end
                            meals_.values(Index) = round(plan.(mealNames{mnIdx}).value(1)+diff(plan.(mealNames{mnIdx}).value)*rand(1));
                            if meals_.values(Index) < 5 % do not count meals less than 5g
                                meals_.values(Index) = 0;
                            end
                            meals_.glycemicLoads(Index) = plan.(mealNames{mnIdx}).glycemicLoad;
                            meals_.announced(Index) = plan.(mealNames{mnIdx}).announcedFraction > rand(1);
                            totalCarbs = totalCarbs + meals_.values(Index);
                        end
                    end
                end
                if iter == 100
                    warning('[RandomMealPlan] Couldn''t generate random meals with max and min carbs: [%d, %d] g.', dailyCarbsMin, dailyCarbsMax);
                end
                this.meals = meals_;
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
