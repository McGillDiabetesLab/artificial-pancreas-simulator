classdef SimulatorOptions
    %SIMULATOROPTIONS  Configuration options for running a simulation.
    %   OPTIONS = SIMULATOROPTIONS() creates a structure whose properties
    %   must be set to configure the artificial pancreas simulator.
    %
    %   See also /ARTIFICIALPANCREASSIMULATOR.
    
    properties (Access = public)
        %SIMULATIONSTARTTIME  Simulation start time.
        %   The time of the day in minutes at which to start the
        %   simulation.
        simulationStartTime = 8 * 60;
        
        %SIMULATIONDURATION  Simulation duration.
        %   The duration of the simulation in minutes.
        simulationDuration = 24 * 60;
        
        %SIMULATIONSTEPSIZE  Simulation step size.
        %   The time between simulation steps in minutes.
        simulationStepSize = 10;
        
        %PARALLELEXECUTION  Parallel execution flag (optional).
        %   An optional flag that turns on parallel execution. If set, the
        %   program will simulate multiple patients in parallel. Defaults
        %   to false.
        parallelExecution = false;
        
        %PROGRESSBAR  progree bar flag (optional).
        %   An optional flag that turns on the progree bar.
        progressBar = true;
        
        %INTERACTIVESIMULATION  Interactive simulation flag (optional).
        %   An optional flag that turns on interactive simulation. Defaults
        %   to false.
        interactiveSimulation = false;
        
        %VIRTUALPATIENTS  Virtual patients configuration.
        %   A cell array defining the virtual population to use in the
        %   simulation. This array can contain as many patient definitions
        %   as needed. Each patient definition consists of a cell array
        %   with the following entries:
        %
        %       patientClass - A string with the name of the VirtualPatient
        %       subclass to use for the patient model.
        %
        %       mealClass - A string with the name of the MealPlan subclass
        %       to use for this patient's meal plan.
        %
        %       exerciseClass - A string with the name of the ExercisePlan
        %       subclass to use for this patient's exercise plan.
        %
        %       primaryControllerClass - A string with the name of the
        %       InfusionController subclass to use for the primary
        %       controller.
        %
        %   In addition, a fifth optional entry can be specified:
        %
        %       secondaryControllerClass - A string with the name of the
        %       InfusionController subclass to use as a secondary
        %       controller whose infusions are ignored by the patient.
        %
        %   Each class name can be replaced with a cell array containing
        %   two elements: the class name and a struct containing optional
        %   parameters to pass to the class constructor.
        %
        %   Example: A simple patient:
        %
        %       this.virtualPatients = { ...
        %           {'SimplePatient', 'EmptyMealPlan', ...
        %           'EmptyExercisePlan', 'DefaultBasalBolus'}, ...
        %           };
        %
        %   Example: A patient with optional parameters:
        %
        %       this.virtualPatients = { ...
        %           {{'HovorkaPatient', struct('name', 'TestPatient')}, ...
        %           'EmptyMealPlan', 'EmptyExercisePlan', ...
        %           'DefaultBasalBolus'}, ...
        %           };
        %
        %   Example: Two controllers for the same patient type:
        %
        %       this.virtualPatients = { ...
        %           {{'HovorkaPatient', struct('name', 'TestPatient')}, ...
        %           'EmptyMealPlan', 'EmptyExercisePlan', ...
        %           'DefaultBasalBolus'}, ...
        %           {{'HovorkaPatient', struct('name', 'TestPatient')}, ...
        %           'EmptyMealPlan', 'EmptyExercisePlan', ...
        %           'DefaultMPC'} ...
        %           };
        %
        %   Example: A patient with both primary and secondary controllers:
        %
        %       this.virtualPatients = { ...
        %           {{'HovorkaPatient', struct('name', 'TestPatient')}, ...
        %           'EmptyMealPlan', 'EmptyExercisePlan', ...
        %           'DefaultBasalBolus', 'DefaultMPC'} ...
        %           };
        virtualPatients;
        
        %RESULTSMANAGER  Results manager configuration.
        %   A string with the name of the ResultsManager subclass to use to
        %   process the results of the simulation. The class name can be
        %   replaced with a cell array containing two elements: the class
        %   name and a struct containing optional parameters to pass to the
        %   results manager.
        %
        %   Example: A simple results manager:
        %
        %       this.resultsManager = 'DefaultResultsManager';
        %
        %   Example: A results manager with a custom configuration:
        %
        %       this.resultsManager = {'DefaultResultsManager', ...
        %           struct('showSummary', true)};
        resultsManager;
    end
    
    methods (Static)
        function out = getVirtualPatients()
            out = SimulatorOptions.getObjects('virtual-patients');
        end
        
        function out = getInfusionControllers()
            out = SimulatorOptions.getObjects('controllers');
        end
        
        function out = getMealPlans()
            out = SimulatorOptions.getObjects('meal-plans');
        end
        
        function out = getExercisePlans()
            out = SimulatorOptions.getObjects('exercise-plans');
        end
        
        function out = getResultsManagers()
            out = SimulatorOptions.getObjects('results-managers');
        end
        
        function classes = getObjects(directoryName)
            classes = {};
            paths = strsplit(path, ';');
            for i = 1:numel(paths)
                directory = dir(strcat(paths{i}, filesep, directoryName));
                for index = 1:numel(directory)
                    filename = directory(index).name;
                    startIndex = regexp(filename, '^@.*$');
                    if startIndex == 1
                        classes{end+1, 1} = extractAfter(filename, 1);
                    end
                end
            end
        end
        
        function options = getOptions(classname)
            %GETOPTIONS  Get list of default options for a simulator
            %   classname.
            
            options = struct();
            
            dummyOpt = SimulatorOptions;
            dummyOpt.simulationDuration = 8 * 60; % minutes
            dummyOpt.simulationStartTime = 0 * 60; % minutes
            dummyOpt.simulationStepSize = 10; % minutes
            dummyOpt.resultsManager = 'ResultsManagerTemplate';
            
            if contains(which(classname), 'patient', 'IgnoreCase', true)
                dummyOpt.virtualPatients{1} = { ...
                    classname, ...
                    'MealPlanTemplate', ...
                    'ExercisePlanTemplate', ...
                    'InfusionControllerTemplate'};
                dummySim = ArtificialPancreasSimulator(dummyOpt);
                if isprop(dummySim.patients{1}, 'opt')
                    options = dummySim.patients{1}.opt;
                end
            elseif contains(which(classname), 'mealplan', 'IgnoreCase', true)
                dummyOpt.virtualPatients{1} = { ...
                    'VirtualPatientTemplate', ...
                    classname, ...
                    'ExercisePlanTemplate', ...
                    'InfusionControllerTemplate'};
                dummySim = ArtificialPancreasSimulator(dummyOpt);
                if isprop(dummySim.patients{1}.mealPlan, 'opt')
                    options = dummySim.patients{1}.mealPlan.opt;
                end
            elseif contains(which(classname), 'exercise', 'IgnoreCase', true)
                dummyOpt.virtualPatients{1} = { ...
                    'VirtualPatientTemplate', ...
                    'MealPlanTemplate', ...
                    classname, ...
                    'InfusionControllerTemplate'};
                dummySim = ArtificialPancreasSimulator(dummyOpt);
                if isprop(dummySim.patients{1}.exercisePlan, 'opt')
                    options = dummySim.patients{1}.exercisePlan.opt;
                end
            elseif contains(which(classname), 'controller', 'IgnoreCase', true)
                dummyOpt.virtualPatients{1} = { ...
                    'VirtualPatientTemplate', ...
                    'MealPlanTemplate', ...
                    'ExercisePlanTemplate', ...
                    classname};
                dummySim = ArtificialPancreasSimulator(dummyOpt);
                if isprop(dummySim.primaryControllers{1}, 'opt')
                    options = dummySim.primaryControllers{1}.opt;
                end
            end
        end
    end
end
