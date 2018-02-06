function deleteResultsManager(handles)
%DELETERESULTSMANAGER  Delete the selected custom results manager.

if ~isempty(handles.ResultsManagerCustomClasses.UserData)
    %% Get the index of the selected custom results manager.
    value = handles.ResultsManagerCustomClasses.Value;
    
    %% Delete the selected custom results manager.
    handles.ResultsManagerCustomClasses.UserData(value) = [];
    
    %% Save and let the load function update the GUI.
    saveResultsManagers(handles);
    loadResultsManagers(handles.ResultsManagerCustomClasses);
    loadResultsManagers(handles.ResultsManager);
    
    %% Update the selected results managers in the GUI.
    handles.ResultsManagerCustomClasses.Value = min(handles.ResultsManagerCustomClasses.Value, ...
        numel(handles.ResultsManagerCustomClasses.String));
    handles.ResultsManager.Value = min(handles.ResultsManager.Value, ...
        numel(handles.ResultsManager.String));
    saveResultsManagerIndex(handles);
end

end

