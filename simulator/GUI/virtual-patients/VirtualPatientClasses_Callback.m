function VirtualPatientClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    selectVirtualPatient(handles);
end

end

