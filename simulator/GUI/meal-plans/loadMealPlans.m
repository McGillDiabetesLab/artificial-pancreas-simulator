function loadMealPlans(hObject)
%LOADMEALPLANS  Load the saved custom meal plans from the user's configuration.

hObject.String = {''};
hObject.UserData = [];

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'mealPlans') && ~isempty(configuration.mealPlans)
        mealPlans = configuration.mealPlans;
        names = {};
        for i = 1:numel(mealPlans)
            names{i} = mealPlans{i}.options.name;
        end
        
        hObject.String = names;
        hObject.UserData = mealPlans;
    end
end

end

