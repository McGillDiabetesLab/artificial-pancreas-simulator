function selectResultsManager(handles)
%SELECTRESULTSMANAGER  Create a new custom results manager from the selected results manager class.

%% Get the name of the selected results manager class.
className = handles.ResultsManagerClasses.String{handles.ResultsManagerClasses.Value};

%% Configure the selected results manager class.
eval(['options = ', className, '.configure(className);']);
if isempty(options)
    return;
end

%% Add the configured results manager class to the custom results managers.
handles.ResultsManagerCustomClasses.UserData{end+1} = struct('className', className, 'options', options);

%% Save and let the load function update the GUI.
saveResultsManagers(handles);
loadResultsManagers(handles.ResultsManagerCustomClasses);
loadResultsManagers(handles.ResultsManager);

end

