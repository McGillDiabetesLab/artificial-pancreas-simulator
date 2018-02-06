function loadPrimaryControllerIndex(hObject)
%LOADPRIMARYCONTROLLERINDEX  Load the primary controller index from the user's configuration.

hObject.Value = 1;

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'primaryControllerIndex') && ~isempty(configuration.primaryControllerIndex)
        hObject.Value = configuration.primaryControllerIndex;
    end
end

end

