%SIMULATION  Run the artificial pancreas simulator without GUI.

% Set paths
run('../configurePaths');

% Set simulation options
options = SimulatorOptions;
options.simulationStartTime = 8 * 60; % minutes
options.simulationDuration = 24 * 60; % minutes
options.simulationStepSize = 10; % minutes
options.virtualPatients = {{ ...
    'HovorkaPatient', ...
    'DailyMealPlan', ...
    'EmptyExercisePlan', ...
    'PumpTherapy'}};

options.resultsManager = 'PublishResultsManager';

% Run simulation
simulator = ArtificialPancreasSimulator(options);
simulator.simulate();
