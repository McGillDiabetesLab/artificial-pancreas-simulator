function ExercisePlanClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    selectExercisePlan(handles);
end

end

