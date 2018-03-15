classdef ResultsManager < matlab.mixin.Copyable
    %RESULTSMANAGER  Abstract class that manages simulation results.
    %   This class provides an interface for the user to define how they
    %   want their results to be managed. It stores the patient's glucose
    %   level and infusions and provides hooks for the user to process
    %   these results.
    %
    %   Implementation Notes:
    %
    %       The DISPLAYRESULTS static method must be implemented in the
    %       subclass. See this method's documentation for more details.
    %
    %       The constructor for the subclass must have the signature
    %       THIS = SUBCLASS(...) where ... are the parameters of the
    %       RESULTSMANAGER constructor.
    %
    %       The CONFIGURE static method can be overridden to provide a
    %       graphical user interface for configuring the OPTIONS struct
    %       used in the DISPLAYRESULTS method.
    %
    %       To assist in the implementation of the subclass, the
    %       SIMULATIONSTARTTIME, SIMULATIONDURATION, SIMULATIONSTEPSIZE,
    %       PATIENT, PRIMARYCONTROLLER, SECONDARYCONTROLLER,
    %       GLUCOSEMEASUREMENTTIMES, GLUCOSEMEASUREMENTS,
    %       PRIMARYINFUSIONTIMES, PRIMARYINFUSIONS, SECONDARYINFUSIONTIMES,
    %       and SECONDARYINFUSIONS properties are provided. See each
    %       property's documentation for more details.
    %
    %   See also /ARTIFICIALPANCREASSIMULATOR, /VIRTUALPATIENT,
    %   /INFUSIONCONTROLLER.
    
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
    
    properties(GetAccess = public, SetAccess = {?ArtificialPancreasSimulator})
        %PATIENT  Patient being treated.
        %   The patient being monitored and treated.
        patient;
        
        %PRIMARYCONTROLLER  Primary infusion controller.
        %   The infusion controller whose recommendations are used to
        %   administer infusions to the patient.
        primaryController;
        
        %SECONDARYCONTROLLER  Secondary infusion controller.
        %   An optional secondary controller whose recommendations are
        %   recorded but are not administered to the patient. This
        %   property is an empty array when not in use.
        secondaryController;
        
        %GLUCOSEMEASUREMENTTIMES  Glucose measurement times.
        %   A cell array containing the times in minutes at which glucose
        %   measurements were recorded.
        glucoseMeasurementTimes = {};
        
        %GLUCOSEMEASUREMENTS  Glucose measurements.
        %   A cell array containing the glucose measurements recorded.
        %   These measurements are recorded in mmol/L.
        glucoseMeasurements = {};
        
        %PRIMARYINFUSIONTIMES  Primary infusion times.
        %   A cell array containing the times in minutes at which primary
        %   infusions were recorded.
        primaryInfusionTimes = {};
        
        %PRIMARYINFUSIONS  Primary infusions.
        %   A cell array containing the primary infusions recorded. These
        %   infusions are recorded as structs with the following fields:
        %
        %       basalInsulin - Basal insulin rate in U/h.
        %
        %       bolusInsulin - Bolus insulin in U.
        %
        %       basalGlucagon - Basal glucagon rate in ug/h (optional).
        %
        %       bolusGlucagon - Bolus glucagon in ug (optional).
        primaryInfusions = {};
        
        %SECONDARYINFUSIONTIMES  Secondary infusion times.
        %   A cell array containing the times in minutes at which secondary
        %   infusions were recorded.
        secondaryInfusionTimes = {};
        
        %SECONDARYINFUSIONS  Secondary infusions.
        %   A cell array containing the secondary infusions recorded. These
        %   infusions are recorded as structs with the following fields:
        %
        %       basalInsulin - Basal insulin rate in U/h.
        %
        %       bolusInsulin - Bolus insulin in U.
        %
        %       basalGlucagon - Basal glucagon rate in ug/h (optional).
        %
        %       bolusGlucagon - Bolus glucagon in ug (optional).
        secondaryInfusions = {};
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
    
    methods(Static, Abstract)
        %DISPLAYRESULTS  Display the saved simulation results.
        %   DISPLAYRESULTS(RESULTSMANAGERS, OPTIONS) processes the
        %   simulation results from multiple results managers of the same
        %   type. RESULTSMANAGERS is a cell array of results managers of
        %   the same type. OPTIONS is an optional struct that contains
        %   additional configuration options.
        %
        %   Implementation Notes:
        %
        %       This method can access any private properties and methods
        %       of the subclass implementation.
        %
        %       This method should not assume that the simulation has
        %       completed. It is possible for this method to be called with
        %       partial results during interactive simulations.
        %
        %       The processing of the results does not have to be
        %       restricted to plotting each patient's results
        %       independently. Possible alternatives include plotting a
        %       statistical summary of all the patient's results and saving
        %       the results to a file.
        displayResults(resultsManagers, options);
    end
    
    methods
        function this = ResultsManager(simulationStartTime, simulationDuration, simulationStepSize, patient, primaryController, secondaryController)
            %RESULTSMANAGER  Default constructor.
            
            % Check number of input arguments.
            narginchk(6, 6);
            
            % Parse input arguments.
            p = inputParser;
            checkVirtualPatient = @(patient) isa(patient, 'VirtualPatient');
            checkInfusionController = @(controller) isa(controller, 'InfusionController');
            checkOptionalInfusionController = @(controller) isempty(controller) || isa(controller, 'InfusionController');
            addRequired(p, 'simulationStartTime', @isnumeric);
            addRequired(p, 'simulationDuration', @isnumeric);
            addRequired(p, 'simulationStepSize', @isnumeric);
            addRequired(p, 'patient', checkVirtualPatient);
            addRequired(p, 'primaryController', checkInfusionController);
            addRequired(p, 'secondaryController', checkOptionalInfusionController);
            parse(p, simulationStartTime, simulationDuration, simulationStepSize, patient, primaryController, secondaryController);
            
            % Set properties.
            this.simulationStartTime = simulationStartTime;
            this.simulationDuration = simulationDuration;
            this.simulationStepSize = simulationStepSize;
            this.patient = patient;
            this.primaryController = primaryController;
            this.secondaryController = secondaryController;
        end
        
        function addGlucoseMeasurement(this, time, glucose)
            %ADDGLUCOSEMEASUREMENT  Record the given glucose measurement.
            %   ADDGLUCOSEMEASUREMENT(TIME, GLUCOSE) records the given
            %   time and glucose measurement. TIME is given in minutes.
            %   GLUCOSE is given in mmol/L.
            
            this.glucoseMeasurementTimes{end+1} = time;
            this.glucoseMeasurements{end+1} = glucose;
        end
        
        function addPrimaryInfusions(this, time, infusions)
            %ADDPRIMARYINFUSIONS  Record the given primary infusions.
            %   ADDPRIMARYINFUSIONS(TIME, INFUSIONS) records the given time
            %   and primary infusions. TIME is given in minutes. INFUSIONS
            %   is a struct with the following fields:
            %
            %       basalInsulin - Basal insulin rate in U/h.
            %
            %       bolusInsulin - Bolus insulin in U.
            %
            %       basalGlucagon - Basal glucagon rate in ug/h (optional).
            %
            %       bolusGlucagon - Bolus glucagon in ug (optional).
            
            this.primaryInfusionTimes{end+1} = time;
            this.primaryInfusions{end+1} = infusions;
        end
        
        function addSecondaryInfusions(this, time, infusions)
            %ADDSECONDARYINFUSIONS  Record the given secondary infusions.
            %   ADDSECONDARYINFUSIONS(TIME, INFUSIONS) records the given
            %   time and secondary infusions. TIME is given in minutes.
            %   INFUSIONS is a struct with the following fields:
            %
            %       basalInsulin - Basal insulin rate in U/h.
            %
            %       bolusInsulin - Bolus insulin in U.
            %
            %       basalGlucagon - Basal glucagon rate in ug/h (optional).
            %
            %       bolusGlucagon - Bolus glucagon in ug (optional).
            
            this.secondaryInfusionTimes{end+1} = time;
            this.secondaryInfusions{end+1} = infusions;
        end
    end
    
end

