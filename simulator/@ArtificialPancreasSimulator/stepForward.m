function stepForward(this)
%STEPFORWARD  Simulate a single step of the interactive simulation.
%   STEPFORWARD() simulates a single step of the interactive simulation and
%   displays the results.
%
%   See also GETCURRENTTIME, STEPBACKWARD, JUMPTOTIME.

if ~this.options.interactiveSimulation
    error('This method is only enabled during interactive simulation.');
end

if this.getCurrentTime() >= this.options.simulationStartTime + this.options.simulationDuration
    return;
end

this.simulateForward();

if ~isempty(this.resultsManagerOptions)
    eval([class(this.resultsManagers{1}), ...
        '.displayResults(this.resultsManagers, this.resultsManagerOptions);']);
else
    eval([class(this.resultsManagers{1}), ...
        '.displayResults(this.resultsManagers);']);
end

end

