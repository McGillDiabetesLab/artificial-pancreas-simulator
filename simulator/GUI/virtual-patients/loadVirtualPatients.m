function loadVirtualPatients(hObject)
%LOADVIRTUALPATIENTS  Load the saved custom virtual patients from the user's configuration.

hObject.String = {''};
hObject.UserData = [];

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'virtualPatients') && ~isempty(configuration.virtualPatients)
        virtualPatients = configuration.virtualPatients;
        names = {};
        for i = 1:numel(virtualPatients)
            names{i} = virtualPatients{i}.options.name;
        end
        
        hObject.String = names;
        hObject.UserData = virtualPatients;
    end
end

end

