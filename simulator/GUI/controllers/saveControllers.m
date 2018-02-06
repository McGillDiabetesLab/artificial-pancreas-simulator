function saveControllers(handles)
%SAVECONTROLLERS  Save the custom controllers to the user's configuration.

controllers = handles.ControllerCustomClasses.UserData;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'controllers', '-append');
else
    save(getConfigurationFilename(), 'controllers');
end

end

