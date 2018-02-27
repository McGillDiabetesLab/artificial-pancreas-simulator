function StartButton_Callback(hObject, eventdata, handles)

if strcmp(handles.StartButton.String, 'Stop')
    handles.StepForwardButton.Enable = 'off';
    handles.StepBackwardButton.Enable = 'off';
    handles.JumpToStartButton.Enable = 'off';
    handles.JumpToEndButton.Enable = 'off';
    handles.CurrentTime.Enable = 'off';
    handles.StartButton.String = 'Start';
    return;
end

if isempty(handles.StartTime.String)
    errordlg('Missing simulation start time.');
    return;
end

if isempty(handles.Duration.String)
    errordlg('Missing simulation duration.');
    return;
end

if isempty(handles.StepSize.String)
    errordlg('Missing simulation step size.');
    return;
end

if isempty(handles.VirtualPatient.UserData)
    errordlg('Missing virtual patient.');
    return;
end

if isempty(handles.MealPlan.UserData)
    errordlg('Missing meal plan.');
    return;
end

if isempty(handles.ExercisePlan.UserData)
    errordlg('Missing exercise plan.');
    return;
end

if isempty(handles.PrimaryController.UserData)
    errordlg('Missing primary controller.');
    return;
end

if isempty(handles.ResultsManager.UserData)
    errordlg('Missing results manager.');
    return;
end

startTime = parseTime(handles.StartTime.String);
if isempty(startTime)
    errordlg('Invalid simulation start time.');
    return;
end

duration = parseTime(handles.Duration.String);
if isempty(duration)
    errordlg('Invalid simulation duration.');
    return;
end

stepSize = parseTime(handles.StepSize.String);
if isempty(stepSize)
    errordlg('Invalid simulation step size.');
    return;
end

options = SimulatorOptions();
options.simulationStartTime = startTime;
options.simulationDuration = duration;
options.simulationStepSize = stepSize;
options.parallelExecution = false;
options.interactiveSimulation = handles.InteractiveSimulationCheckbox.Value;

virtualPatient = handles.VirtualPatient.UserData{handles.VirtualPatient.Value};
mealPlan = handles.MealPlan.UserData{handles.MealPlan.Value};
exercisePlan = handles.ExercisePlan.UserData{handles.ExercisePlan.Value};

primaryController = handles.PrimaryController.UserData{handles.PrimaryController.Value};
secondaryController = struct('className', '', 'options', struct('name', ''));
if handles.SecondaryController.Value ~= 1
    secondaryController = handles.SecondaryController.UserData{handles.SecondaryController.Value-1};
end

options.virtualPatients = { ...
    {virtualPatient.className, virtualPatient.options}, ...
    {mealPlan.className, mealPlan.options}, ...
    {exercisePlan.className, exercisePlan.options}, ...
    {primaryController.className, primaryController.options}, ...
    };
if ~isempty(secondaryController.className)
    options.virtualPatients{end+1} = ...
        {secondaryController.className, secondaryController.options};
end
options.virtualPatients = {options.virtualPatients};

options.resultsManager = { ...
    handles.ResultsManager.UserData{handles.ResultsManager.Value}.className, ...
    handles.ResultsManager.UserData{handles.ResultsManager.Value}.options, ...
    };

% Keep the simulator in the global environment.
global simulator;
simulator = ArtificialPancreasSimulator(options);

if handles.InteractiveSimulationCheckbox.Value
    handles.Root.UserData.simulator = simulator;
    handles.CurrentTime.String = formatTime(simulator.getCurrentTime(), true);
    handles.StepForwardButton.Enable = 'on';
    handles.StepBackwardButton.Enable = 'on';
    handles.JumpToStartButton.Enable = 'on';
    handles.JumpToEndButton.Enable = 'on';
    handles.CurrentTime.Enable = 'on';
    handles.StartButton.String = 'Stop';
else
    simulator.simulate();
end

end
