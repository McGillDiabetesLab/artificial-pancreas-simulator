%INLINESIM  Example of the artificial pancreas simulator command line.

clc,
clear,

% Make sure all paths are set correctly
run('../configurePaths');

options = SimulatorOptions;
options.simulationDuration = 24 * 60; % minutes
options.simulationStartTime = 8 * 60; % minutes
options.simulationStepSize = 10; % minutes
options.parallelExecution = false;
options.resultsManager = 'PublishResultsManager';

optPatient = options.getOptions('HovorkaPatient');
optPatient.patient = {'patientAvg'};
optPatient.sensorNoiseType = 'ar(1)';
optPatient.intraVariability = 0.6;
optPatient.mealVariability = 0.4;
optPatient.RNGSeed = 7;

% Set virtual patient options
options.virtualPatients{1} = { ...
    {'HovorkaPatient', optPatient}, ...
    'DailyMealPlan', ...
    'EmptyExercisePlan', ...
    'PumpTherapy'};

simulator = ArtificialPancreasSimulator(options);
simulator.simulate();
