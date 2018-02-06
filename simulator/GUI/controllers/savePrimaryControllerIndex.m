function savePrimaryControllerIndex(handles)
%SAVEPRIMARYCONTROLLERINDEX  Save the primary controller index to the user's configuration.

primaryControllerIndex = handles.PrimaryController.Value;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'primaryControllerIndex', '-append');
else
    save(getConfigurationFilename(), 'primaryControllerIndex');
end

end

