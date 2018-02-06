function loadResultsManagerIndex(hObject)
%LOADRESULTSMANAGERINDEX  Load the results manager index from the user's configuration.

hObject.Value = 1;

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'resultsManagerIndex') && ~isempty(configuration.resultsManagerIndex)
        hObject.Value = configuration.resultsManagerIndex;
    end
end

end

