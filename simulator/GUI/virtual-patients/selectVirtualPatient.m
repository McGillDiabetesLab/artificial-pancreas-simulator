function selectVirtualPatient(handles)
%SELECTVIRTUALPATIENT  Create a new custom virtual patient from the selected virtual patient class.

%% Get the name of the selected virtual patient class.
className = handles.VirtualPatientClasses.String{handles.VirtualPatientClasses.Value};

%% Configure the selected virtual patient class.
eval(['options = ', className, '.configure(className);']);
if isempty(options)
    return;
end

%% Add the configured virtual patient class to the custom virtual patients.
handles.VirtualPatientCustomClasses.UserData{end+1} = struct('className', className, 'options', options);

%% Save and let the load function update the GUI.
saveVirtualPatients(handles);
loadVirtualPatients(handles.VirtualPatientCustomClasses);
loadVirtualPatients(handles.VirtualPatient);

end

