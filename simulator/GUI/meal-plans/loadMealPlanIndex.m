function loadMealPlanIndex(hObject)
%LOADMEALPLANINDEX  Load the meal plan index from the user's configuration.

hObject.Value = 1;

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'mealPlanIndex') && ~isempty(configuration.mealPlanIndex)
        hObject.Value = configuration.mealPlanIndex;
    end
end

end

