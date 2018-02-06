function ControllerClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    selectController(handles);
end

end

