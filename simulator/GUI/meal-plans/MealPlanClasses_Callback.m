function MealPlanClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    selectMealPlan(handles);
end

end

