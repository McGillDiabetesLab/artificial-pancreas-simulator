function saveMealPlans(handles)
%SAVEMEALPLANS  Save the custom meal plans to the user's configuration.

mealPlans = handles.MealPlanCustomClasses.UserData;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'mealPlans', '-append');
else
    save(getConfigurationFilename(), 'mealPlans');
end

end

