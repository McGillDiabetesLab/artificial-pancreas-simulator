function loadControllers(hObject, isSecondaryController)
%LOADCONTROLLERS  Load the saved custom controllers from the user's configuration.

hObject.String = {''};
hObject.UserData = [];

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'controllers') && ~isempty(configuration.controllers)
        controllers = configuration.controllers;
        names = {};
        if isSecondaryController
            names{end+1} = '';
        end
        for i = 1:numel(controllers)
            names{end+1} = controllers{i}.options.name;
        end
        
        hObject.String = names;
        hObject.UserData = controllers;
    end
end

end

