function loadDuration(hObject)
%LOADDURATION  Load the saved duration from the user's configuration.

hObject.String = '';

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'duration') && ~isempty(configuration.duration)
        hObject.String = configuration.duration;
    end
end

end

