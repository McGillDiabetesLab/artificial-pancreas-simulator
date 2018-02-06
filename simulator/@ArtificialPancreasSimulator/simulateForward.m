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
    t = this.simulationTime;
    
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
end

this.simulationTime = this.simulationTime + this.options.simulationStepSize;

end

