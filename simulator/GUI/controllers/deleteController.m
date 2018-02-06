function deleteController(handles)
%DELETECONTROLLER  Delete the selected custom controller.

if ~isempty(handles.ControllerCustomClasses.UserData)
    %% Get the index of the selected custom controller.
    value = handles.ControllerCustomClasses.Value;
    
    %% Delete the selected custom controller.
    handles.ControllerCustomClasses.UserData(value) = [];
    
    %% Save and let the load function update the GUI.
    saveControllers(handles);
    loadControllers(handles.ControllerCustomClasses, false);
    loadControllers(handles.PrimaryController, false);
    loadControllers(handles.SecondaryController, true);
    
    %% Update the selected controllers in the GUI.
    handles.ControllerCustomClasses.Value = min(handles.ControllerCustomClasses.Value, ...
        numel(handles.ControllerCustomClasses.String));
    handles.PrimaryController.Value = min(handles.PrimaryController.Value, ...
        numel(handles.PrimaryController.String));
    savePrimaryControllerIndex(handles);
    handles.SecondaryController.Value = min(handles.SecondaryController.Value, ...
        numel(handles.SecondaryController.String));
    saveSecondaryControllerIndex(handles);
end

end

