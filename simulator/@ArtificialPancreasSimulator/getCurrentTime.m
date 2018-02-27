function time = getCurrentTime(this)
%GETCURRENTTIME  Get the current interactive simulation time.
%   TIME = GETCURRENTTIME() returns the current interactive simulation time
%   in minutes. This is the last time at which a measurement was recorded.
%
%   See also STEPFORWARD, STEPBACKWARD, JUMPTOTIME.

if ~this.options.interactiveSimulation
    error('This method is only enabled during interactive simulation.');
end

time = this.simulationTime;

end
