function StepForwardButton_Callback(hObject, eventdata, handles)

simulator = handles.Root.UserData.simulator;
simulator.stepForward();
handles.CurrentTime.String = formatTime(simulator.getCurrentTime(), true);

end

