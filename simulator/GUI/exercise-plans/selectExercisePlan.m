function selectExercisePlan(handles)
%SELECTEXERCISEPLAN  Create a new custom exercise plan from the selected exercise plan class.

%% Get the name of the selected exercise plan class.
className = handles.ExercisePlanClasses.String{handles.ExercisePlanClasses.Value};

%% Configure the selected exercise plan class.
eval(['options = ', className, '.configure(className);']);
if isempty(options)
    return;
end

%% Add the configured exercise plan class to the custom exercise plans.
handles.ExercisePlanCustomClasses.UserData{end+1} = struct('className', className, 'options', options);

%% Save and let the load function update the GUI.
saveExercisePlans(handles);
loadExercisePlans(handles.ExercisePlanCustomClasses);
loadExercisePlans(handles.ExercisePlan);

end

