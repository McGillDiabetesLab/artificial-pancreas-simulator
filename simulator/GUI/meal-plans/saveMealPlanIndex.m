function saveMealPlanIndex(handles)
%SAVEMEALPLANINDEX  Save the meal plan index to the user's configuration.

mealPlanIndex = handles.MealPlan.Value;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'mealPlanIndex', '-append');
else
    save(getConfigurationFilename(), 'mealPlanIndex');
end

end

