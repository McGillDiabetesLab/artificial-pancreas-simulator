function StartTime_Callback(hObject, eventdata, handles)

startTime = parseTime(handles.StartTime.String);
if isempty(startTime)
    errordlg('Invalid simulation start time.');
    loadStartTime(hObject);
    return;
end
handles.StartTime.String = formatTime(startTime, false);
startTime = handles.StartTime.String;

if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'startTime', '-append');
else
    save(getConfigurationFilename(), 'startTime');
end

end

