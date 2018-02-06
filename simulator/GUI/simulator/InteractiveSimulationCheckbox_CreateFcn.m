function InteractiveSimulationCheckbox_CreateFcn(hObject, eventdata, handles)

hObject.Value = false;

if exist(getConfigurationFilename(), 'file') == 2
    configuration = load(getConfigurationFilename());
    if isfield(configuration, 'interactiveSimulationCheckbox') && ~isempty(configuration.interactiveSimulationCheckbox)
        hObject.Value = configuration.interactiveSimulationCheckbox;
    end
end

end

