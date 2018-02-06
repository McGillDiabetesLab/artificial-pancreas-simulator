function saveExercisePlans(handles)
%SAVEEXERCISEPLANS  Save the custom exercise plans to the user's configuration.

exercisePlans = handles.ExercisePlanCustomClasses.UserData;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'exercisePlans', '-append');
else
    save(getConfigurationFilename(), 'exercisePlans');
end

end

