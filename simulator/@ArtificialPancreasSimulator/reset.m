function reset(this, patientIndexes)
%RESET  Reset the simulator properties to the initial configuration.

if nargin < 2
    patientIndexes = 1:numel(this.configuration.patients);
end
    
for i = patientIndexes(:)'
    this.patients{i} = copy(this.configuration.patients{i});
    
    this.primaryControllers{i} = copy(this.configuration.primaryControllers{i});
    this.primaryControllers{i}.patient = this.patients{i};
    
    this.secondaryControllers{i} = [];
    if ~isempty(this.configuration.secondaryControllers{i})
        this.secondaryControllers{i} = copy(this.configuration.secondaryControllers{i});
        this.secondaryControllers{i}.patient = this.patients{i};
    end
    
    this.resultsManagers{i} = copy(this.configuration.resultsManagers{i});
    this.resultsManagers{i}.patient = this.patients{i};
    this.resultsManagers{i}.primaryController = this.primaryControllers{i};
    this.resultsManagers{i}.secondaryController = this.secondaryControllers{i};
end

end

