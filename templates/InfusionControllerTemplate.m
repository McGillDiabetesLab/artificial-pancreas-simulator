classdef InfusionControllerTemplate < InfusionController

    properties (GetAccess = public, SetAccess = private)
        % Declare any internal variables used by the class here.

    end

    methods
        function this = InfusionControllerTemplate(simulationDuration, simulationStartTime, simulationStepSize, patient, options)
            % Default constructor

            % Calls the base class constructor to initialize the base object. This is required.
            this@InfusionController(simulationDuration, simulationStartTime, simulationStepSize, patient);

            % Write your code to initialize the infusion controller here.

        end

        function infusions = getInfusions(this, currentTime)
            % Define how other entities (such as the virtual patient) get the current infusions here.
            infusions.basalInsulin = 0; % Example: set the basal insulin.
            infusions.bolusInsulin = round(this.patient.getMeal(currentTime).value / 10); % Example: set the bolus insulin.
        end
        
        function setInfusions(this, time, infusions)
            % Nothing to do since we don't store infusions history.
        end
    end

    methods (Access = private)
        % Define any additional internal functions here. These functions
        % cannot be accessed from outside of this class.

    end

end

