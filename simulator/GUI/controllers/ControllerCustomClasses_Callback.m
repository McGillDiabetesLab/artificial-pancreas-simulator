function ControllerCustomClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    editController(handles);
end

end

