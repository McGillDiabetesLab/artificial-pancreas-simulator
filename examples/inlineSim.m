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

optMeal = options.getOptions('DailyMealPlan');
optMeal.meals(5).repeat = 0;
optMeal.meals(5).time = 9*60;
optMeal.meals(5).value = 20;
optMeal.meals(5).glycemicLoad = 5;
optMeal.meals(5).announcedFraction = 0;

optPump = options.getOptions('PumpTherapy');
optPump.manualBolus.time = [8*60];
optPump.manualBolus.type = {'percent'};
optPump.manualBolus.value = [0.3];

optExerc = options.getOptions('DailyExercisePlan');
optExerc.exercises(2) = [];

% Set virtual patient options
options.virtualPatients{1} = { ...
    {'HovorkaPatient', optPatient}, ...
    {'DailyMealPlan', optMeal}, ...
    {'DailyExercisePlan', optExerc}, ...
    {'PumpTherapy', optPump}};

simulator = ArtificialPancreasSimulator(options);
simulator.simulate();
