function saveVirtualPatientIndex(handles)
%SAVEVIRTUALPATIENTINDEX  Save the virtual patient index to the user's configuration.

virtualPatientIndex = handles.VirtualPatient.Value;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'virtualPatientIndex', '-append');
else
    save(getConfigurationFilename(), 'virtualPatientIndex');
end

end

