classdef MealPlan < matlab.mixin.Copyable
    %MEALPLAN  Abstract class representing a patient meal plan.
    %   This class provides an interface for obtaining the current meal to
    %   be administered to a patient. It also provides an interface for
    %   recording and obtaining the treatments (rescue carbs) ingested by
    %   the patient during the simulation.
    %
    %   Implementation Notes:
    %
    %       The GETMEAL method must be implemented in the subclass. See
    %       this method's documentation for more details.
    %
    %       The constructor for the subclass must have the signature
    %       THIS = SUBCLASS(..., OPTIONS) where ... are the parameters of
    %       the MEALPLAN constructor and OPTIONS is an optional struct that
    %       contains additional configuration options for the subclass.
    %
    %       The CONFIGURE static method can be overridden to provide a
    %       graphical user interface for configuring the OPTIONS struct
    %       used in the constructor.
    %
    %       The NAME property provides a way of identifying the MEALPLAN
    %       instance. By default, it is set to the subclass name. It is
    %       recommended to overwrite it with the NAME field in the OPTIONS
    %       struct passed to the constructor.
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
    
    properties(GetAccess = public, SetAccess = private)
        %TREATMENTS  Record of treatments (rescue carbs) ingested.
        %   A record of the carbs ingested outside of the meal plan.
        treatments;
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
        %GETMEAL  Get a meal for the patient.
        %   MEAL = GETMEAL(TIME) returns the meal to be administered to the
        %   patient at the given time. TIME is given in minutes. MEAL is a
        %   struct that contains the following fields:
        %
        %       value - Size of the meal in grams (g).
        %
        %       glycemicLoad - Fraction representing the glycemic load of
        %       the meal on the patient.
        meal = getMeal(this, time);
    end
    
    methods
        function this = MealPlan(simulationStartTime, simulationDuration, simulationStepSize)
            %MEALPLAN  Default constructor.
            
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
            
            intervals = simulationDuration ./ simulationStepSize;
            if rem(intervals, 1) ~= 0
                error('The simulation step size must evenly divide the simulation duration.');
            end
            this.treatments = sparse(intervals+1, 1);
        end
        
        function addTreatment(this, time, value)
            %ADDTREATMENT  Record a treatment (rescue carbs).
            %   ADDTREATMENT(TIME, VALUE) records a treatment that
            %   has been ingested by the patient at the given time.
            %   TIME is given in minutes. VALUE is the size of the
            %   treatment in grams (g).
            
            index = round((time - this.simulationStartTime)./this.simulationStepSize) + 1;
            this.treatments(index) = value;
        end
        
        function value = getTreatment(this, time)
            %GETTREATMENT  Get the treatment (rescue carbs) ingested.
            %   VALUE = GETTREATMENT(TIME) returns the value of the
            %   treatment that was ingested by the patient at the given
            %   time. TIME is given in minutes. VALUE is the size of the
            %   treatment in grams (g).
            
            index = round((time - this.simulationStartTime)./this.simulationStepSize) + 1;
            value = this.treatments(index);
        end
    end
    
end

