function saveResultsManagers(handles)
%SAVERESULTSMANAGERS  Save the custom results managers to the user's configuration.

resultsManagers = handles.ResultsManagerCustomClasses.UserData;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'resultsManagers', '-append');
else
    save(getConfigurationFilename(), 'resultsManagers');
end

end

