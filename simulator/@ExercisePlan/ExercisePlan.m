classdef ExercisePlan < matlab.mixin.Copyable
    %EXERCISEPLAN  Abstract class representing a patient exercise plan.
    %   This class provides an interface for obtaining the current exercise
    %   to be administered to a patient.
    %
    %   Implementation Notes:
    %
    %       The GETEXERCISE method must be implemented in the subclass. See
    %       this method's documentation for more details.
    %
    %       The constructor for the subclass must have the signature
    %       THIS = SUBCLASS(..., OPTIONS) where ... are the parameters of
    %       the EXERCISEPLAN constructor and OPTIONS is an optional struct
    %       that contains additional configuration options for the
    %       subclass.
    %
    %       The CONFIGURE static method can be overridden to provide a
    %       graphical user interface for configuring the OPTIONS struct
    %       used in the constructor.
    %
    %       The NAME property provides a way of identifying the
    %       EXERCISEPLAN instance. By default, it is set to the subclass
    %       name. It is recommended to overwrite it with the NAME field in
    %       the OPTIONS struct passed to the constructor.
    %
    %       To assist in the implementation of the subclass, the
    %       SIMULATIONSTARTTIME, SIMULATIONDURATION, and SIMULATIONSTEPSIZE
    %       properties are provided. See each property's documentation for
    %       more details.
    %
    %   See also /ARTIFICIALPANCREASSIMULATOR.
    
    properties(GetAccess = public, SetAccess = immutable)
        %SIMULATIONSTARTTIME  Simulation start time.
        %   The time of the day in minutes at which the simulation starts.
        simulationStartTime;
        
        %SIMULATIONDURATION  Simulation duration.
        %   The duration of the simulation in minutes.
        simulationDuration;
        
        %SIMULATIONSTEPSIZE  Simulation step size.
        %   The time between simulation steps in minutes.
        simulationStepSize;
    end
    
    properties(GetAccess = public, SetAccess = protected)
        %NAME  Object identifier.
        name;
    end
    
    methods(Static)
        function options = configure(className, lastOptions)
            %CONFIGURE  Input dialog box for configuring the class.
            %   OPTIONS = CONFIGURE(CLASSNAME, LASTOPTIONS) returns a
            %   struct OPTIONS that contains the optional parameters to be
            %   passed to the constructor of the subclass or an empty
            %   matrix on failure. CLASSNAME is the name of the subclass
            %   for which this method was called. LASTOPTIONS is an
            %   optional struct that contains the previous configuration
            %   options that were chosen.
            %
            %   Implementation Notes:
            %
            %       If overriding this method, the only requirement is that
            %       the OPTIONS struct contains the NAME field so the
            %       configuration can be labeled.
            %
            %   See also CONFIGURENAME.
            
            if ~exist('lastOptions', 'var')
                lastOptions = struct('name', className);
            end
            options = configureName(className, lastOptions);
        end
    end
    
    methods(Abstract)
        %GETEXERCISE  Get an exercise for the patient.
        %   EXERCISE = GETEXERCISE(TIME) returns the exercise to be
        %   performed by the patient at the given time. TIME is given in
        %   minutes. EXERCISE is a struct that contains the following
        %   fields:
        %
        %       startTime - Time at which the exercise starts in minutes.
        %
        %       endTime - Time at which the exercise ends in minutes.
        %
        %       intensity - Fraction representing the intensity of the
        %       exercise.
        %
        %       type - Type of exercise ('aerobic', 'anaerobic',
        %       'resistance').
        exercise = getExercise(this, time);
    end
    
    methods
        function this = ExercisePlan(simulationStartTime, simulationDuration, simulationStepSize)
            %EXERCISEPLAN  Default constructor.
            
            % Check number of input arguments.
            narginchk(3, 3);
            
            % Parse input arguments.
            p = inputParser;
            addRequired(p, 'simulationStartTime', @isnumeric);
            addRequired(p, 'simulationDuration', @isnumeric);
            addRequired(p, 'simulationStepSize', @isnumeric);
            parse(p, simulationStartTime, simulationDuration, simulationStepSize);
            
            % Set properties.
            this.simulationStartTime = simulationStartTime;
            this.simulationDuration = simulationDuration;
            this.simulationStepSize = simulationStepSize;
            this.name = class(this);
        end
    end
    
end

