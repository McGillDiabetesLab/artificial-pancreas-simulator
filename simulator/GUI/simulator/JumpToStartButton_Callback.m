function JumpToStartButton_Callback(hObject, eventdata, handles)

simulator = handles.Root.UserData.simulator;
simulator.jumpToTime(simulator.options.simulationStartTime);
handles.CurrentTime.String = formatTime(simulator.getCurrentTime(), true);

end

