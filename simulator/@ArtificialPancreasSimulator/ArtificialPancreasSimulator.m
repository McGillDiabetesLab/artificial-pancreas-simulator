classdef ArtificialPancreasSimulator < handle
    %ARTIFICIALPANCREASSIMULATOR  Artificial pancreas simulator.
    %   SIMULATOR = ARTIFICIALPANCREASSIMULATOR(OPTIONS) creates a
    %   simulator for type 1 diabetes patients undergoing treatment
    %   according to the configuration specified by OPTIONS. OPTIONS is an
    %   instance of SimulatorOptions.
    %
    %   According to the options specified, the simulator can then be used
    %   to either run a standard simulation using the SIMULATE method, or
    %   an interactive simulation using the GETCURRENTTIME, STEPFORWARD,
    %   STEPBACKWARD, and JUMPTOTIME methods. In either case, the current
    %   results can be accessed through the simulator's read-only public
    %   properties. See each method's documentation for more details.
    %
    %   See also /SIMULATOROPTIONS, /VIRTUALPATIENT, /MEALPLAN,
    %   /EXERCISEPLAN, /INFUSIONCONTROLLER, /RESULTSMANAGER.
    
    properties(GetAccess = public, SetAccess = private)
        %OPTIONS  Simulator options.
        options;
        
        %PATIENTS  Virtual patients.
        %   A cell array of the virtual patients undergoing treatment.
        patients;
        
        %PRIMARYCONTROLLERS  Primary infusion controllers.
        %   A cell array of each patient's primary infusion controller.
        primaryControllers;
        
        %SECONDARYCONTROLLERS  Optional secondary infusion controllers.
        %   A cell array of each patient's optional secondary infusion
        %   controller.
        secondaryControllers;
        
        %RESULTSMANAGERS  Results managers.
        %   A cell array of each patient's results manager.
        resultsManagers;
    end
    
    methods
        function this = ArtificialPancreasSimulator(options)
            %ARTIFICIALPANCREASSIMULATOR  Default constructor.
            
            % Check number of input arguments.
            narginchk(1, 1);
            
            % Parse input arguments.
            p = inputParser;
            checkOptions = @(options) isa(options, 'SimulatorOptions');
            addRequired(p, 'options', checkOptions);
            parse(p, options);
            
            % Set properties.
            this.options = options;
            this.configure();
            this.reset();
        end
        
        % Standard simulation.
        simulate(this, patientIndex);
        
        % Interactive simulation.
        time = getCurrentTime(this);
        stepForward(this);
        stepBackward(this);
        jumpToTime(this, time);
    end
    
    properties(Access = private)
        configuration; % Saved instantiation of the constructor options.
        resultsManagerOptions;
        
        % Standard simulation.
        firstSimulation = true;
        
        % Interactive simulation.
        simulationTime; % Next time to be recorded.
        saveIndex = 0;
        savedPatients = {};
        savedPrimaryControllers = {};
        savedSecondaryControllers = {};
        savedResultsManagers = {};
    end
    
    methods(Access = private)
        configure(this);
        reset(this, patientIndex);
        
        % Interactive simulation.
        simulateForward(this);
        simulateBackward(this);
    end
    
end

