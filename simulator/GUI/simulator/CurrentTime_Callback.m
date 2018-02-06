function CurrentTime_Callback(hObject, eventdata, handles)

simulator = handles.Root.UserData.simulator;
simulator.jumpToTime(parseTime(handles.CurrentTime.String));
handles.CurrentTime.String = formatTime(simulator.getCurrentTime(), true);

end

