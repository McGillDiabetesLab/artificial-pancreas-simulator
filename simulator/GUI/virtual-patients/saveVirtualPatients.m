function saveVirtualPatients(handles)
%SAVEVIRTUALPATIENTS  Save the custom virtual patients to the user's configuration.

virtualPatients = handles.VirtualPatientCustomClasses.UserData;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'virtualPatients', '-append');
else
    save(getConfigurationFilename(), 'virtualPatients');
end

end

