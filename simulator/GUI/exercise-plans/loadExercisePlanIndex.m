function loadExercisePlanIndex(hObject)
%LOADEXERCISEPLANINDEX  Load the exercise plan index from the user's configuration.

hObject.Value = 1;

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'exercisePlanIndex') && ~isempty(configuration.exercisePlanIndex)
        hObject.Value = configuration.exercisePlanIndex;
    end
end

end

