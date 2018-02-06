function ExercisePlanCustomClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    editExercisePlan(handles);
end

end

