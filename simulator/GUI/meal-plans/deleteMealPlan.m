function deleteMealPlan(handles)
%DELETEMEALPLAN  Delete the selected custom meal plan.

if ~isempty(handles.MealPlanCustomClasses.UserData)
    %% Get the index of the selected custom meal plan.
    value = handles.MealPlanCustomClasses.Value;
    
    %% Delete the selected custom meal plan.
    handles.MealPlanCustomClasses.UserData(value) = [];
    
    %% Save and let the load function update the GUI.
    saveMealPlans(handles);
    loadMealPlans(handles.MealPlanCustomClasses);
    loadMealPlans(handles.MealPlan);
    
    %% Update the selected meal plans in the GUI.
    handles.MealPlanCustomClasses.Value = min(handles.MealPlanCustomClasses.Value, ...
        numel(handles.MealPlanCustomClasses.String));
    handles.MealPlan.Value = min(handles.MealPlan.Value, ...
        numel(handles.MealPlan.String));
    saveMealPlanIndex(handles);
end

end

