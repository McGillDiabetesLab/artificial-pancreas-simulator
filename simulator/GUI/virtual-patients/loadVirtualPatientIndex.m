function loadVirtualPatientIndex(hObject)
%LOADVIRTUALPATIENTINDEX  Load the virtual patient index from the user's configuration.

hObject.Value = 1;

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'virtualPatientIndex') && ~isempty(configuration.virtualPatientIndex)
        hObject.Value = configuration.virtualPatientIndex;
    end
end

end

