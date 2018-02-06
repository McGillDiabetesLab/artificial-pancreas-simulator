function saveSecondaryControllerIndex(handles)
%SAVESECONDARYCONTROLLERINDEX  Save the secondary controller index to the user's configuration.

secondaryControllerIndex = handles.SecondaryController.Value;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'secondaryControllerIndex', '-append');
else
    save(getConfigurationFilename(), 'secondaryControllerIndex');
end

end

