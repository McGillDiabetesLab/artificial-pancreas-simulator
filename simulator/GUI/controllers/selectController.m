function selectController(handles)
%SELECTCONTROLLER  Create a new custom controller from the selected controller class.

%% Get the name of the selected controller class.
className = handles.ControllerClasses.String{handles.ControllerClasses.Value};

%% Configure the selected controller class.
eval(['options = ', className, '.configure(className);']);
if isempty(options)
    return;
end

%% Add the configured controller class to the custom controllers.
handles.ControllerCustomClasses.UserData{end+1} = struct('className', className, 'options', options);

%% Save and let the load function update the GUI.
saveControllers(handles);
loadControllers(handles.ControllerCustomClasses, false);
loadControllers(handles.PrimaryController, false);
loadControllers(handles.SecondaryController, true);

end

