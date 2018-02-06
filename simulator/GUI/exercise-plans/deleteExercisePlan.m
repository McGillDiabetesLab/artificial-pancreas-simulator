function deleteExercisePlan(handles)
%DELETEEXERCISEPLAN  Delete the selected custom exercise plan.

if ~isempty(handles.ExercisePlanCustomClasses.UserData)
    %% Get the index of the selected custom exercise plan.
    value = handles.ExercisePlanCustomClasses.Value;
    
    %% Delete the selected custom exercise plan.
    handles.ExercisePlanCustomClasses.UserData(value) = [];
    
    %% Save and let the load function update the GUI.
    saveExercisePlans(handles);
    loadExercisePlans(handles.ExercisePlanCustomClasses);
    loadExercisePlans(handles.ExercisePlan);
    
    %% Update the selected exercise plans in the GUI.
    handles.ExercisePlanCustomClasses.Value = min(handles.ExercisePlanCustomClasses.Value, ...
        numel(handles.ExercisePlanCustomClasses.String));
    handles.ExercisePlan.Value = min(handles.ExercisePlan.Value, ...
        numel(handles.ExercisePlan.String));
    saveExercisePlanIndex(handles);
end

end

