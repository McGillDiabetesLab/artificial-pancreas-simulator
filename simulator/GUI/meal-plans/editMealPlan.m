function editMealPlan(handles)
%EDITMEALPLAN  Edit the selected custom meal plan's configuration.

if ~isempty(handles.MealPlanCustomClasses.UserData)
    %% Get the index of the selected custom meal plan.
    value = handles.MealPlanCustomClasses.Value;
    
    %% Reconfigure the selected custom meal plan.
    className = handles.MealPlanCustomClasses.UserData{value}.className;
    lastOptions = handles.MealPlanCustomClasses.UserData{value}.options;
    eval(['options = ', className, '.configure(className, lastOptions);']);
    if isempty(options)
        return;
    end
    handles.MealPlanCustomClasses.UserData{value}.options = options;
    
    %% Save and let the load function update the GUI.
    saveMealPlans(handles);
    loadMealPlans(handles.MealPlanCustomClasses);
    loadMealPlans(handles.MealPlan);
end

end

