function saveExercisePlanIndex(handles)
%SAVEEXERCISEPLANINDEX  Save the exercise plan index to the user's configuration.

exercisePlanIndex = handles.ExercisePlan.Value;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'exercisePlanIndex', '-append');
else
    save(getConfigurationFilename(), 'exercisePlanIndex');
end

end

