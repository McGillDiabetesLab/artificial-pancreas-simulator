function loadExercisePlans(hObject)
%LOADEXERCISEPLANS  Load the saved custom exercise plans from the user's configuration.

hObject.String = {''};
hObject.UserData = [];

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'exercisePlans') && ~isempty(configuration.exercisePlans)
        exercisePlans = configuration.exercisePlans;
        names = {};
        for i = 1:numel(exercisePlans)
            names{i} = exercisePlans{i}.options.name;
        end
        
        hObject.String = names;
        hObject.UserData = exercisePlans;
    end
end

end

