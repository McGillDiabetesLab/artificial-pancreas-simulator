function loadResultsManagers(hObject)
%LOADRESULTSMANAGERS  Load the saved custom results managers from the user's configuration.

hObject.String = {''};
hObject.UserData = [];

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'resultsManagers') && ~isempty(configuration.resultsManagers)
        resultsManagers = configuration.resultsManagers;
        names = {};
        for i = 1:numel(resultsManagers)
            names{i} = resultsManagers{i}.options.name;
        end
        
        hObject.String = names;
        hObject.UserData = resultsManagers;
    end
end

end

