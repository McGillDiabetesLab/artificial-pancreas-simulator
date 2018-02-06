function StepSize_Callback(hObject, eventdata, handles)

stepSize = parseTime(handles.StepSize.String);
if isempty(stepSize)
    errordlg('Invalid simulation step size.');
    loadStepSize(hObject);
    return;
end
handles.StepSize.String = formatTime(stepSize, false);
stepSize = handles.StepSize.String;

if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'stepSize', '-append');
else
    save(getConfigurationFilename(), 'stepSize');
end

end

