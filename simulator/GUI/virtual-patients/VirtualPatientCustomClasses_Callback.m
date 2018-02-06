function VirtualPatientCustomClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    editVirtualPatient(handles);
end

end

