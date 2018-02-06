function saveResultsManagerIndex(handles)
%SAVERESULTSMANAGERINDEX  Save the results manager index to the user's configuration.

resultsManagerIndex = handles.ResultsManager.Value;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'resultsManagerIndex', '-append');
else
    save(getConfigurationFilename(), 'resultsManagerIndex');
end

end

