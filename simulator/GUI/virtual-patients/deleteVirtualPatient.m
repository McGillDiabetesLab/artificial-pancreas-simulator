function deleteVirtualPatient(handles)
%DELETEVIRTUALPATIENT  Delete the selected custom virtual patient.

if ~isempty(handles.VirtualPatientCustomClasses.UserData)
    %% Get the index of the selected custom virtual patient.
    value = handles.VirtualPatientCustomClasses.Value;
    
    %% Delete the selected custom virtual patient.
    handles.VirtualPatientCustomClasses.UserData(value) = [];
    
    %% Save and let the load function update the GUI.
    saveVirtualPatients(handles);
    loadVirtualPatients(handles.VirtualPatientCustomClasses);
    loadVirtualPatients(handles.VirtualPatient);
    
    %% Update the selected virtual patients in the GUI.
    handles.VirtualPatientCustomClasses.Value = min(handles.VirtualPatientCustomClasses.Value, ...
        numel(handles.VirtualPatientCustomClasses.String));
    handles.VirtualPatient.Value = min(handles.VirtualPatient.Value, ...
        numel(handles.VirtualPatient.String));
    saveVirtualPatientIndex(handles);
end

end

