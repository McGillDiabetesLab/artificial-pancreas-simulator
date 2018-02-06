function InteractiveSimulationCheckbox_Callback(hObject, eventdata, handles)

interactiveSimulationCheckbox = handles.InteractiveSimulationCheckbox.Value;
if exist(getConfigurationFilename(), 'file') == 2
    save(getConfigurationFilename(), 'interactiveSimulationCheckbox', '-append');
else
    save(getConfigurationFilename(), 'interactiveSimulationCheckbox');
end

end

