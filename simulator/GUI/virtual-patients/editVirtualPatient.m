function editVirtualPatient(handles)
%EDITVIRTUALPATIENT  Edit the selected custom virtual patient's configuration.

if ~isempty(handles.VirtualPatientCustomClasses.UserData)
    %% Get the index of the selected custom virtual patient.
    value = handles.VirtualPatientCustomClasses.Value;
    
    %% Reconfigure the selected custom virtual patient.
    className = handles.VirtualPatientCustomClasses.UserData{value}.className;
    lastOptions = handles.VirtualPatientCustomClasses.UserData{value}.options;
    eval(['options = ', className, '.configure(className, lastOptions);']);
    if isempty(options)
        return;
    end
    handles.VirtualPatientCustomClasses.UserData{value}.options = options;
    
    %% Save and let the load function update the GUI.
    saveVirtualPatients(handles);
    loadVirtualPatients(handles.VirtualPatientCustomClasses);
    loadVirtualPatients(handles.VirtualPatient);
end

end

