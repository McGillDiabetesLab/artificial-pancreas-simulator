classdef DailyExercisePlan < ExercisePlan
    
    properties (GetAccess = public, SetAccess = private)
        exercises % The precomputed daily activity values
        opt;
    end
    
    methods (Static)
        function options = configure(className, lastOptions)
            defaultAns = struct();
            defaultAns.exerciseTable = cell(50, 6);
            if ~exist('lastOptions', 'var')
                defaultAns.name = className;
                defaultAns.exerciseTable(1, :) = {true, 'Morning', formatTime(9*60, false), '60', '70', 'aerobic'};
                defaultAns.exerciseTable(2, :) = {true, 'Afternoon', formatTime(14*60, false), '90', '30', 'aerobic'};
            else
                defaultAns.name = lastOptions.name;
                for i = 1:numel(lastOptions.exercises)
                    defaultAns.exerciseTable(i, :) = { ...
                        lastOptions.exercises(i).repeat, ...
                        lastOptions.exercises(i).description, ...
                        formatTime(lastOptions.exercises(i).time, false), ...
                        num2str(lastOptions.exercises(i).duration), ...
                        num2str(100*lastOptions.exercises(i).intensity), ...
                        ExercisePlan.typesOfExercise{lastOptions.exercises(i).type}};
                end
            end
            
            dlgTitle = 'Configure Daily Exercise Plan';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Plan name:', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200; % Automatically assign the height.
            
            prompt(end+1, :) = {'', 'exerciseTable', []};
            formats(end+1, 1).type = 'table';
            formats(end, 1).format = {'logical', 'char', 'char', 'char', 'char', ExercisePlan.typesOfExercise};
            formats(end, 1).items = {'Repeat', 'Description', 'Time (DD HH:MM)', 'Duration (min)', 'Intensity (%)', 'Type'};
            formats(end, 1).size = [552, 200];
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, defaultAns);
            
            options = [];
            if ~cancelled
                options.name = answer.name;
                
                for i = 1:size(answer.exerciseTable, 1)
                    if ~isempty(answer.exerciseTable{i, 3})
                        if isempty(answer.exerciseTable{i, 1})
                            options.exercises(i).repeat = false;
                        else
                            options.exercises(i).repeat = answer.exerciseTable{i, 1};
                        end
                        options.exercises(i).description = answer.exerciseTable{i, 2};
                        options.exercises(i).time = parseTime(answer.exerciseTable{i, 3});
                        options.exercises(i).duration = str2double(answer.exerciseTable{i, 4});
                        if isempty(answer.exerciseTable{i, 5})
                            options.exercises(i).intensity = 1;
                        else
                            options.exercises(i).intensity = str2double(answer.exerciseTable{i, 5}) / 100;
                        end
                        if isempty(answer.exerciseTable{i, 6})
                            options.exercises(i).type = 1;
                        else
                            options.exercises(i).type = find(strcmpi(ExercisePlan.typesOfExercise, answer.exerciseTable{i, 6}));
                        end
                    end
                end
            end
        end
    end
    
    methods
        function this = DailyExercisePlan(simulationStartTime, simulationDuration, simulationStepSize, options)
            this@ExercisePlan(simulationStartTime, simulationDuration, simulationStepSize);
            
            % Parse options.
            this.opt = struct();
            this.opt.name = this.name;
            this.opt.exercises = table2struct(table( ...
                logical([1; 1]), ...
                [9; 14]*60, ...
                [60; 90], ...
                [0.7; 0.3], ...
                [1; 1], ...
                'VariableNames', {'repeat', 'time', 'duration', 'intensity', 'type'}));
            
            if exist('options', 'var')
                f = fields(this.opt);
                for i = 1:numel(f)
                    if isfield(options, f{i})
                        this.opt.(f{i}) = options.(f{i});
                    end
                end
            end
            
            % Compute number of steps.
            numDays = ceil((simulationStartTime + simulationDuration)/(24 * 60)) + 1;
            numSteps = ceil(numDays*24*60/simulationStepSize);
            
            % Uses sparse matrices for efficient storage
            this.exercises.durations = sparse(numSteps, 1);
            this.exercises.intensities = sparse(numSteps, 1);
            this.exercises.types = sparse(numSteps, 1);
            
            % Fill exercises from exercise table.
            for i = 1:numel(this.opt.exercises)
                index = floor(this.opt.exercises(i).time/this.simulationStepSize) + 1;
                
                this.exercises.durations(index) = this.opt.exercises(i).duration;
                this.exercises.intensities(index) = this.opt.exercises(i).intensity;
                this.exercises.types(index) = this.opt.exercises(i).type;
                
                if this.opt.exercises(i).repeat
                    day = 1;
                    index = floor((this.opt.exercises(i).time + day * 24 * 60)/this.simulationStepSize) + 1;
                    while index <= numSteps
                        this.exercises.durations(index) = this.opt.exercises(i).duration;
                        this.exercises.intensities(index) = this.opt.exercises(i).intensity;
                        this.exercises.types(index) = this.opt.exercises(i).type;
                        day = day + 1;
                        index = floor((this.opt.exercises(i).time + day * 24 * 60)/this.simulationStepSize) + 1;
                    end
                end
            end
        end
        
        function exercise = getExercise(this, time)
            index = round(time/this.simulationStepSize) + 1;
            
            exercise.duration = this.exercises.durations(index);
            exercise.intensity = this.exercises.intensities(index);
            exercise.type = this.exercises.types(index);
            exercise.announced = ones(size(exercise.type)); %TODO
        end
        
    end
    
end
