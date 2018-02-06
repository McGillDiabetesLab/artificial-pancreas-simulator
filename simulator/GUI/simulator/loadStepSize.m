function loadStepSize(hObject)
%LOADSTEPSIZE  Load the saved step size from the user's configuration.

hObject.String = '';

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'stepSize') && ~isempty(configuration.stepSize)
        hObject.String = configuration.stepSize;
    end
end

end

