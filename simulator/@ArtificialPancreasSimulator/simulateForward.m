function simulateForward(this)
%SIMULATEFORWARD  Simulate a single step of the interactive simulation.

if ~this.options.interactiveSimulation
    error('This method is only enabled during interactive simulation.');
end

if this.getCurrentTime() >= this.options.simulationStartTime + this.options.simulationDuration
    return;
end

%% Save the current state.
this.saveIndex = this.saveIndex + 1;

savedPatients = {};
savedPrimaryControllers = {};
savedSecondaryControllers = {};
savedResultsManagers = {};

for i = 1:numel(this.patients)
    savedPatients{i} = copy(this.patients{i});
    
    savedPrimaryControllers{i} = copy(this.primaryControllers{i});
    savedPrimaryControllers{i}.patient = savedPatients{i};
    
    savedSecondaryControllers{i} = [];
    if ~isempty(this.secondaryControllers{i})
        savedSecondaryControllers{i} = copy(this.secondaryControllers{i});
        savedSecondaryControllers{i}.patient = savedPatients{i};
    end
    
    savedResultsManagers{i} = copy(this.resultsManagers{i});
    savedResultsManagers{i}.patient = savedPatients{i};
    savedResultsManagers{i}.primaryController = savedPrimaryControllers{i};
    savedResultsManagers{i}.secondaryController = savedSecondaryControllers{i};
end

this.savedPatients{this.saveIndex} = savedPatients;
this.savedPrimaryControllers{this.saveIndex} = savedPrimaryControllers;
this.savedSecondaryControllers{this.saveIndex} = savedSecondaryControllers;
this.savedResultsManagers{this.saveIndex} = savedResultsManagers;

%% Simulate the next state.
for i = 1:numel(this.patients)
    patient = this.patients{i};
    primaryController = this.primaryControllers{i};
    secondaryController = this.secondaryControllers{i};
    resultsManager = this.resultsManagers{i};
    time = this.simulationTime;
    
    primaryInfusions = primaryController.getInfusions(time);
    resultsManager.addPrimaryInfusions(time, primaryInfusions);
    primaryController.setInfusions(time, primaryInfusions);
    
    if ~isempty(secondaryController)
        secondaryInfusions = secondaryController.getInfusions(time);
        resultsManager.addSecondaryInfusions(time, secondaryInfusions);
        secondaryController.setInfusions(time, primaryInfusions);
    end
    
    patient.updateState(time, time+this.options.simulationStepSize, primaryInfusions);
    
    glucoseMeasurement = patient.getGlucoseMeasurement();
    resultsManager.addGlucoseMeasurement(time+this.options.simulationStepSize, glucoseMeasurement);
    
    tracerInfo = patient.getTracerInfo();
    resultsManager.addTracerMeasurement(time+this.options.simulationStepSize, tracerInfo);
end

this.simulationTime = this.simulationTime + this.options.simulationStepSize;

end
