function simulateBackward(this)
%SIMULATEBACKWARD  Revert a single step of the interactive simulation.

if ~this.options.interactiveSimulation
    error('This method is only enabled during interactive simulation.');
end

if this.getCurrentTime() <= this.options.simulationStartTime
    return;
end

%% Restore the previous state.
for i = 1:numel(this.patients)
    this.patients{i} = this.savedPatients{this.saveIndex}{i};
    this.primaryControllers{i} = this.savedPrimaryControllers{this.saveIndex}{i};
    this.secondaryControllers{i} = this.savedSecondaryControllers{this.saveIndex}{i};
    this.resultsManagers{i} = this.savedResultsManagers{this.saveIndex}{i};
end

this.saveIndex = this.saveIndex - 1;

this.simulationTime = this.simulationTime - this.options.simulationStepSize;

end

