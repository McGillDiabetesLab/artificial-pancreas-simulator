function editController(handles)
%EDITCONTROLLER  Edit the selected custom controller's configuration.

if ~isempty(handles.ControllerCustomClasses.UserData)
    %% Get the index of the selected custom controller.
    value = handles.ControllerCustomClasses.Value;
    
    %% Reconfigure the selected custom controller.
    className = handles.ControllerCustomClasses.UserData{value}.className;
    lastOptions = handles.ControllerCustomClasses.UserData{value}.options;
    eval(['options = ', className, '.configure(className, lastOptions);']);
    if isempty(options)
        return;
    end
    handles.ControllerCustomClasses.UserData{value}.options = options;
    
    %% Save and let the load function update the GUI.
    saveControllers(handles);
    loadControllers(handles.ControllerCustomClasses, false);
    loadControllers(handles.PrimaryController, false);
    loadControllers(handles.SecondaryController, true);
end

end

