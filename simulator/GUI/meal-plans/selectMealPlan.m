function selectMealPlan(handles)
%SELECTMEALPLAN  Create a new custom meal plan from the selected meal plan class.

%% Get the name of the selected meal plan class.
className = handles.MealPlanClasses.String{handles.MealPlanClasses.Value};

%% Configure the selected meal plan class.
eval(['options = ', className, '.configure(className);']);
if isempty(options)
    return;
end

%% Add the configured meal plan class to the custom meal plans.
handles.MealPlanCustomClasses.UserData{end+1} = struct('className', className, 'options', options);

%% Save and let the load function update the GUI.
saveMealPlans(handles);
loadMealPlans(handles.MealPlanCustomClasses);
loadMealPlans(handles.MealPlan);

end

