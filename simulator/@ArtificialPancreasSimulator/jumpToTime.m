function jumpToTime(this, time)
%JUMPTOTIME  Move the interactive simulation to the given time.
%   JUMPTOTIME(TIME) moves the interactive simulation to the given time and
%   displays the results. TIME is given in minutes.
%
%   See also GETCURRENTTIME, STEPFORWARD, STEPBACKWARD.

if ~this.options.interactiveSimulation
    error('This method is only enabled during interactive simulation.');
end

if time < this.options.simulationStartTime
    return;
end

if time > this.options.simulationStartTime + this.options.simulationDuration
    return;
end

if rem(time-this.options.simulationStartTime, this.options.simulationStepSize) ~= 0
    return;
end

while this.getCurrentTime() < time
    this.simulateForward();
end

while this.getCurrentTime() > time
    this.simulateBackward();
end

if ~isempty(this.resultsManagerOptions)
    eval([class(this.resultsManagers{1}), ...
        '.displayResults(this.resultsManagers, this.resultsManagerOptions);']);
else
    eval([class(this.resultsManagers{1}), ...
        '.displayResults(this.resultsManagers);']);
end

end

