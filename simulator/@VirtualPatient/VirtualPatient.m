classdef VirtualPatient < matlab.mixin.Copyable
    %VIRTUALPATIENT  Abstract class representing a virtual patient.
    %   This class provides an interface for interacting with a virtual
    %   patient during simulation. This includes obtaining the current
    %   blood glucose level and administering infusions to the patient. It
    %   also acts as the owner of MealPlan and ExercisePlan objects and
    %   provides an interface for obtaining the meals and treatments
    %   (rescue carbs) administered and the exercises performed.
    %
    %   Implementation Notes:
    %
    %       The GETPROPERTIES, GETGLUCOSEMEASUREMENT, and UPDATESTATE
    %       methods must be implemented in the subclass. See each method's
    %       documentation for more details.
    %
    %       The constructor for the subclass must have the signature
    %       THIS = SUBCLASS(..., OPTIONS) where ... are the parameters of
    %       the VIRTUALPATIENT constructor and OPTIONS is an optional
    %       struct that contains additional configuration options for the
    %       subclass.
    %
    %       The CONFIGURE static method can be overridden to provide a
    %       graphical user interface for configuring the OPTIONS struct
    %       used in the constructor.
    %
    %       The NAME property provides a way of identifying the
    %       VIRTUALPATIENT instance. By default, it is set to the subclass
    %       name. It is recommended to overwrite it with the NAME field in
    %       the OPTIONS struct passed to the constructor.
    %
    %       To assist in the implementation of the subclass, the MEALPLAN
    %       and EXERCISEPLAN properties are provided. See each property's
    %       documentation for more details.
    %
    %   See also /ARTIFICIALPANCREASSIMULATOR, /MEALPLAN, /EXERCISEPLAN.
    
    properties(GetAccess = public, SetAccess = protected)
        %NAME  Object identifier.
        name;
    end
    
    properties(GetAccess = public, SetAccess = private)
        %MEALPLAN  Meal plan for the patient.
        %   The meals to be administered to the patient. This property also
        %   provides a means of recording treatments (rescue carbs).
        mealPlan;
        
        %EXERCISEPLAN  Exercise plan for the patient.
        %   The exercises to be performed by the patient.
        exercisePlan;
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
        %GETPROPERTIES  Get the patient's properties.
        %   PROP = GETPROPERTIES() returns a struct that contains
        %   fields specific to the patient implementation.
        prop = getProperties(this);
        
        %GETGLUCOSEMEASUREMENT  Get the patient's current glucose level.
        %   GLUCOSE = GETGLUCOSEMEASUREMENT() returns the patient's current
        %   glucose level in mmol/L.
        glucose = getGlucoseMeasurement(this);
        
        %UPDATESTATE  Update the patient's state.
        %   UPDATESTATE(STARTTIME, ENDTIME, INFUSIONS) updates the
        %   patient's state using the given infusions. STARTTIME
        %   corresponds to the simulation time in minutes at which the
        %   function is called, and ENDTIME corresponds to the simulation
        %   time in minutes at which the function returns. INFUSIONS is a
        %   struct with the following fields:
        %
        %       basalInsulin - Basal insulin rate in U/h.
        %
        %       bolusInsulin - Bolus insulin in U.
        %
        %       basalGlucagon - Basal glucagon rate in ug/h (optional).
        %
        %       bolusGlucagon - Bolus glucagon in ug (optional).
        updateState(this, startTime, endTime, infusions);
    end
    
    methods
        function this = VirtualPatient(mealPlan, exercisePlan)
            %VIRTUALPATIENT  Default constructor.
            
            % Check number of input arguments.
            narginchk(2, 2);
            
            % Parse input arguments.
            p = inputParser;
            checkMealPlan = @(mealPlan) isa(mealPlan, 'MealPlan');
            checkExercisePlan = @(exercisePlan) isa(exercisePlan, 'ExercisePlan');
            addRequired(p, 'mealPlan', checkMealPlan);
            addRequired(p, 'exercisePlan', checkExercisePlan);
            parse(p, mealPlan, exercisePlan);
            
            % Set properties.
            this.mealPlan = mealPlan;
            this.exercisePlan = exercisePlan;
            this.name = class(this);
        end
        
        function meal = getMeal(this, time)
            %GETMEAL  Get a meal for the patient.
            %   MEAL = GETMEAL(TIME) returns the meal to be administered to
            %   the patient at the given time. TIME is given in minutes.
            %   MEAL is a struct that contains the following fields:
            %
            %       value - Size of the meal in grams (g).
            %
            %       glycemicLoad - Fraction representing the glycemic load
            %       of the meal on the patient.
            
            meal = this.mealPlan.getMeal(time);
        end
        
        function value = getTreatment(this, time)
            %GETTREATMENT  Get the treatment (rescue carbs) ingested.
            %   VALUE = GETTREATMENT(TIME) returns the value of the
            %   treatment that was ingested by the patient at the given
            %   time. TIME is given in minutes. VALUE is the size of the
            %   treatment in grams (g).
            
            value = this.mealPlan.getTreatment(time);
        end
        
        function exercise = getExercise(this, time)
            %GETEXERCISE  Get an exercise for the patient.
            %   EXERCISE = GETEXERCISE(TIME) returns the exercise to be
            %   performed by the patient at the given time. TIME is given
            %   in minutes. EXERCISE is a struct that contains the
            %   following fields:
            %
            %       startTime - Time at which the exercise starts in
            %       minutes.
            %
            %       endTime - Time at which the exercise ends in minutes.
            %
            %       intensity - Fraction representing the intensity of the
            %       exercise.
            %
            %       type - Type of exercise ('aerobic', 'anaerobic',
            %       'resistance').
            
            exercise = this.exercisePlan.getExercise(time);
        end
    end
    
    methods(Access = protected)
        function cp = copyElement(this)
            %COPYELEMENT  Perform a deep copy of the handle.
            cp = copyElement@matlab.mixin.Copyable(this);
            cp.mealPlan = copy(this.mealPlan);
            cp.exercisePlan = copy(this.exercisePlan);
        end
    end
    
end

