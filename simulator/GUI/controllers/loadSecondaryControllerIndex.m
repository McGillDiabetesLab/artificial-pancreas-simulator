function loadSecondaryControllerIndex(hObject)
%LOADSECONDARYCONTROLLERINDEX  Load the secondary controller index from the user's configuration.

hObject.Value = 1;

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'secondaryControllerIndex') && ~isempty(configuration.secondaryControllerIndex)
        hObject.Value = configuration.secondaryControllerIndex;
    end
end

end

