function MealPlanCustomClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    editMealPlan(handles);
end

end

