function Duration_Callback(hObject, eventdata, handles)

duration = parseTime(handles.Duration.String);
if isempty(duration)
    errordlg('Invalid simulation duration.');
    loadDuration(hObject);
    return;
end
handles.Duration.String = formatTime(duration, false);
duration = handles.Duration.String;

if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'duration', '-append');
else
    save(getConfigurationFilename(), 'duration');
end

end

