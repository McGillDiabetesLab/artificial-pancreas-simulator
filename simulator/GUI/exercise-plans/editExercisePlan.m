function editExercisePlan(handles)
%EDITEXERCISEPLAN  Edit the selected custom exercise plan's configuration.

if ~isempty(handles.ExercisePlanCustomClasses.UserData)
    %% Get the index of the selected custom exercise plan.
    value = handles.ExercisePlanCustomClasses.Value;
    
    %% Reconfigure the selected custom exercise plan.
    className = handles.ExercisePlanCustomClasses.UserData{value}.className;
    lastOptions = handles.ExercisePlanCustomClasses.UserData{value}.options;
    eval(['options = ', className, '.configure(className, lastOptions);']);
    if isempty(options)
        return;
    end
    handles.ExercisePlanCustomClasses.UserData{value}.options = options;
    
    %% Save and let the load function update the GUI.
    saveExercisePlans(handles);
    loadExercisePlans(handles.ExercisePlanCustomClasses);
    loadExercisePlans(handles.ExercisePlan);
end

end

