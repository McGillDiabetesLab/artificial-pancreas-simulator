classdef VirtualPatientTemplate < VirtualPatient
    
    properties(GetAccess = public, SetAccess = private)
        % Declare any internal variables used by the class here.
        n = 10; % Example: the number of elements to hold in the state vector.
        param; % Example: a struct containing the patient model parameters.
        state; % Example: an n x 1 column vector containing the internal patient state.
    end
    
    methods
        function this = VirtualPatientTemplate(mealPlan, exercisePlan, options)
            % Default constructor
            
            % Calls the base class constructor to initialize the base object. This is required.
            this@VirtualPatient(mealPlan, exercisePlan);
            
            % Write your code to initialize the virtual patient here.
            this.param = struct(); % Example: initialize the model parameters to an empty struct.
            %Example: parameters has a name field which is initialized from options.
            if exist('options', 'var') && isfield(options, 'name')
                this.param.name = options.name;
            end
            % Example: initialize the state to a column vector of zeros.
            this.state = zeros(this.n, 1); 
        end
        
        function prop = getProperties(this)
            prop = this.param; % Example: return the internal model parameter struct.
        end
        
        function meas = getGlucoseMeasurement(this)
            meas = this.state(end); % Example: the last element in the state vector could store the glucose level.
        end
        
        function updateState(this, startTime, endTime, infusions)
            % Write your code to update the state of the patient here.
            
            Ubasal = infusions.basalInsulin; % Example: get the current basal insulin infusions.
            Ubolus = infusions.bolusInsulin; % Example: get the current bolus insulin infusions.
            
            meal = this.mealPlan.getMeal(startTime); % Example: get the current meal.
            exercise = this.exercisePlan.getExercise(startTime); % Example: get the current exercise.
            
            % Write the differential equations relating the patient state to the infusions/meal/exercise here.
            this.state = ones(this.n, 1); % Example: update the state.
        end
    end
    
    methods(Access = private)
        % Define any additional internal functions here. These functions
        % cannot be accessed from outside of this class.
        
    end
    
end
