classdef InfusionController < matlab.mixin.Copyable
    %INFUSIONCONTROLLER  Abstract class representing an infusion controller.
    %   This class provides an interface for interacting with an infusion
    %   controller and obtaining a recommendation on the infusions to
    %   administer to a patient.
    %
    %   Implementation Notes:
    %
    %       The GETINFUSIONS and SETINFUSIONS methods must be implemented
    %       in the subclass. See each method's documentation for more
    %       details.
    %
    %       The constructor for the subclass must have the signature
    %       THIS = SUBCLASS(..., OPTIONS) where ... are the parameters of
    %       the INFUSIONCONTROLLER constructor and OPTIONS is an optional
    %       struct that contains additional configuration options for the
    %       subclass.
    %
    %       The CONFIGURE static method can be overridden to provide a
    %       graphical user interface for configuring the OPTIONS struct
    %       used in the constructor.
    %
    %       The NAME property provides a way of identifying the
    %       INFUSIONCONTROLLER instance. By default, it is set to the
    %       subclass name. It is recommended to overwrite it with the NAME
    %       field in the OPTIONS struct passed to the constructor.
    %
    %       To assist in the implementation of the subclass, the
    %       SIMULATIONSTARTTIME, SIMULATIONDURATION, SIMULATIONSTEPSIZE,
    %       and PATIENT properties are provided. See each property's
    %       documentation for more details.
    %
    %   See also /ARTIFICIALPANCREASSIMULATOR, /VIRTUALPATIENT.
    
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
    
    properties(GetAccess = public, SetAccess = {?ArtificialPancreasSimulator})
        %PATIENT  Patient being treated.
        %   The patient being monitored and treated.
        patient;
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
            options = configureName(lastOptions);
        end
    end
    
    methods(Abstract)
        %GETINFUSIONS  Get the recommended infusions for the patient.
        %   INFUSIONS = GETINFUSIONS(TIME) returns the recommended
        %   infusions for the patient at the given time. TIME is given in
        %   minutes. INFUSIONS is a struct with the following fields:
        %
        %       basalInsulin - Basal insulin rate in U/h.
        %
        %       bolusInsulin - Bolus insulin in U.
        %
        %       basalGlucagon - Basal glucagon rate in ug/h (optional).
        %
        %       bolusGlucagon - Bolus glucagon in ug (optional).
        getInfusions(this, time);
        
        %SETINFUSIONS  Set the actual infusions administered to the patient.
        %   SETINFUSIONS(TIME, INFUSIONS) notifies the infusion controller
        %   of the actual infusions administered to the patient at the
        %   given time. TIME is given in minutes. INFUSIONS is a struct
        %   with the following fields:
        %
        %       basalInsulin - Basal insulin rate in U/h.
        %
        %       bolusInsulin - Bolus insulin in U.
        %
        %       basalGlucagon - Basal glucagon rate in ug/h (optional).
        %
        %       bolusGlucagon - Bolus glucagon in ug (optional).
        setInfusions(this, time, infusions);
    end
    
    methods
        function this = InfusionController(simulationStartTime, simulationDuration, simulationStepSize, patient)
            %INFUSIONCONTROLLER  Default constructor.
            
            % Check number of input arguments.
            narginchk(4, 4);
            
            % Parse input arguments.
            p = inputParser;
            checkVirtualPatient = @(patient) isa(patient, 'VirtualPatient');
            addRequired(p, 'simulationStartTime', @isnumeric);
            addRequired(p, 'simulationDuration', @isnumeric);
            addRequired(p, 'simulationStepSize', @isnumeric);
            addRequired(p, 'patient', checkVirtualPatient);
            parse(p, simulationStartTime, simulationDuration, simulationStepSize, patient);
            
            % Set properties.
            this.simulationStartTime = simulationStartTime;
            this.simulationDuration = simulationDuration;
            this.simulationStepSize = simulationStepSize;
            this.patient = patient;
            this.name = class(this);
        end
    end
    
end

