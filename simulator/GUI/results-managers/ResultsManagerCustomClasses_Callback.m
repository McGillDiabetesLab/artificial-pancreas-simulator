function ResultsManagerCustomClasses_Callback(hObject, eventdata, handles)

if strcmp(handles.Root.SelectionType, 'open')
    editResultsManager(handles);
end

end

