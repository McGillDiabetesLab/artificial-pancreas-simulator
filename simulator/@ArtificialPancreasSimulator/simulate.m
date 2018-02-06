function simulate(this)
%SIMULATE  Simulate a virtual population of type 1 diabetes patients.
%   SIMULATE() performs a fresh simulation of the virtual population
%   defined by the simulator configuration and displays the results to the
%   user using the specified results manager. The results can also be
%   accessed through the simulator's read-only public properties.

if this.options.interactiveSimulation
    error('This method is disabled during interactive simulation.');
end

if ~this.firstSimulation
    this.reset();
end
this.firstSimulation = false;

patients = {};
primaryControllers = {};
secondaryControllers = {};
resultsManagers = {};

stepsPerPatient = this.options.simulationDuration ./ this.options.simulationStepSize;
totalSteps = numel(this.patients) .* stepsPerPatient;

if this.options.parallelExecution
    packetSize = 32;
    progressbar = parfor_progressbar(totalSteps, 'Simulation in progress...');
    for parallelIndex = 1:ceil(numel(this.patients)./packetSize)
        startIndex = (parallelIndex - 1) .* packetSize + 1;
        endIndex = min(parallelIndex.*packetSize, numel(this.patients));
        parfor i = startIndex:endIndex
            [patients{i}, primaryControllers{i}, secondaryControllers{i}, resultsManagers{i}] = ...
                simulatePatient(this, progressbar, i);
        end
    end
    progressbar.close();
else
    progressbar = for_progressbar(totalSteps, 'Simulation in progress...');
    for i = 1:numel(this.patients)
        [patients{i}, primaryControllers{i}, secondaryControllers{i}, resultsManagers{i}] = ...
            simulatePatient(this, progressbar, i);
    end
    progressbar.close();
end

this.patients = patients;
this.primaryControllers = primaryControllers;
this.secondaryControllers = secondaryControllers;
this.resultsManagers = resultsManagers;

if ~isempty(this.resultsManagerOptions)
    eval([class(this.resultsManagers{1}), ...
        '.displayResults(this.resultsManagers, this.resultsManagerOptions);']);
else
    eval([class(this.resultsManagers{1}), ...
        '.displayResults(this.resultsManagers);']);
end

end

function [patient, primaryController, secondaryController, resultsManager] = ...
    simulatePatient(this, progressbar, patientIndex)
%SIMULATEPATIENT  Simulate a single virtual patient.

patient = this.patients{patientIndex};
primaryController = this.primaryControllers{patientIndex};
secondaryController = this.secondaryControllers{patientIndex};
resultsManager = this.resultsManagers{patientIndex};

time = this.options.simulationStartTime: ...
    this.options.simulationStepSize: ...
    this.options.simulationStartTime + this.options.simulationDuration;

for t = time(1:end)
    glucoseMeasurement = patient.getGlucoseMeasurement();
    resultsManager.addGlucoseMeasurement(t, glucoseMeasurement);
    
    primaryInfusions = primaryController.getInfusions(t);
    resultsManager.addPrimaryInfusions(t, primaryInfusions);
    primaryController.setInfusions(t, primaryInfusions);
    
    if ~isempty(secondaryController)
        secondaryInfusions = secondaryController.getInfusions(t);
        resultsManager.addSecondaryInfusions(t, secondaryInfusions);
        secondaryController.setInfusions(t, primaryInfusions);
    end
    
    patient.updateState(t, t+this.options.simulationStepSize, primaryInfusions);
    
    progressbar.iterate(1);
end

end

