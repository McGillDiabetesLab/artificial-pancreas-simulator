function editResultsManager(handles)
%EDITRESULTSMANAGER  Edit the selected custom results manager's configuration.

if ~isempty(handles.ResultsManagerCustomClasses.UserData)
    %% Get the index of the selected custom results manager.
    value = handles.ResultsManagerCustomClasses.Value;
    
    %% Reconfigure the selected custom results manager.
    className = handles.ResultsManagerCustomClasses.UserData{value}.className;
    lastOptions = handles.ResultsManagerCustomClasses.UserData{value}.options;
    eval(['options = ', className, '.configure(className, lastOptions);']);
    if isempty(options)
        return;
    end
    handles.ResultsManagerCustomClasses.UserData{value}.options = options;
    
    %% Save and let the load function update the GUI.
    saveResultsManagers(handles);
    loadResultsManagers(handles.ResultsManagerCustomClasses);
    loadResultsManagers(handles.ResultsManager);
end

end

