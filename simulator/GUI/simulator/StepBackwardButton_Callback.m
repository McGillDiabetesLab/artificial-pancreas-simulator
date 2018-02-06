function StepBackwardButton_Callback(hObject, eventdata, handles)

simulator = handles.Root.UserData.simulator;
simulator.stepBackward();
handles.CurrentTime.String = formatTime(simulator.getCurrentTime(), true);

end

