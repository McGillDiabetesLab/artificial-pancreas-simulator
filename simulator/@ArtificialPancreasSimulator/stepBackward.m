function stepBackward(this)
%STEPBACKWARD  Revert a single step of the interactive simulation.
%   STEPBACKWARD() reverts a single step of the interactive simulation and
%   displays the results.
%
%   See also GETCURRENTTIME, STEPFORWARD, JUMPTOTIME.

if ~this.options.interactiveSimulation
    error('This method is only enabled during interactive simulation.');
end

if this.getCurrentTime() <= this.options.simulationStartTime
    return;
end

this.simulateBackward();

if ~isempty(this.resultsManagerOptions)
    eval([class(this.resultsManagers{1}), ...
        '.displayResults(this.resultsManagers, this.resultsManagerOptions);']);
else
    eval([class(this.resultsManagers{1}), ...
        '.displayResults(this.resultsManagers);']);
end

end

