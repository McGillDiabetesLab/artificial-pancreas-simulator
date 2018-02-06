function loadStartTime(hObject)
%LOADSTARTTIME  Load the saved start time from the user's configuration.

hObject.String = '';

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'startTime') && ~isempty(configuration.startTime)
        hObject.String = configuration.startTime;
    end
end

end

