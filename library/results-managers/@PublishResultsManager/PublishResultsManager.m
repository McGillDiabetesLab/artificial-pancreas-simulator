classdef PublishResultsManager < ResultsManager
    
    properties(GetAccess = public, SetAccess = private)
        figIDs
    end
    
    methods(Static)
        
        %% plotSummary
        plotSummary(resultsManagers);
        %% configure
        function options = configure(className, lastOptions)
            if ~exist('lastOptions', 'var')
                lastOptions = struct();
                lastOptions.name = className;
                lastOptions.title = 'Simulation Plot';
            end
            
            dlgTitle = 'Configure Result Manager';
            
            prompt = {};
            formats = {};
            
            prompt(end+1, :) = {'Result manager :', 'name', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200;
            
            prompt(end+1, :) = {'Title :', 'title', []};
            formats(end+1, 1).type = 'edit';
            formats(end, 1).format = 'text';
            formats(end, 1).size = 200;
            
            [answer, cancelled] = inputsdlg(prompt, dlgTitle, formats, lastOptions);
            
            options = [];
            if ~cancelled
                options = answer;
            end
        end
        
        %% displayResults
        function displayResults(resultsManagers, options)
            if nargin < 2
                options = struct();
            end
            
            if isfield(options, 'summary') && options.summary
                PublishResultsManager.plotSummary(resultsManagers);
                return;
            end
            
            for i = 1:numel(resultsManagers)
                if isfield(options, 'title')
                    figureTitle = options.title;
                else
                    figureTitle = sprintf('Simulation #%d - %s', ...
                        i, ...
                        resultsManagers{i}.patient.name);
                end
                
                if isfield(options, 'grayscale')
                    grayscale = options.grayscale;
                else
                    grayscale = false;
                end
                
                if ishandle(i)
                    h = figure(i);
                    set(h, 'name', figureTitle, ...
                        'numbertitle', 'off', ...
                        'defaultAxesColorOrder', [[1, 0, 0]; [0, 0, 1]]);
                else
                    h = figure(i);
                    set(h, 'name', figureTitle, ...
                        'numbertitle', 'off', ...
                        'Units', 'normalized', ...
                        'PaperType', 'usletter', ...
                        'PaperOrientation', 'landscape', ...
                        'PaperPosition', [-0.7, 0.5, 12.0, 7.0], ...
                        'Position', [0.1, 0.1, 0.8, 0.7], ...
                        'defaultAxesColorOrder', [[1, 0, 0]; [0, 0, 1]]);
                end
                clf;
                
                resultsManagers{i}.figIDs = h;
                resultsManagers{i}.plotResults(figureTitle, grayscale);
            end
        end
    end
    
    methods
        function this = PublishResultsManager(simulationStartTime, simulationDuration, simulationStepSize, patient, primaryController, secondaryController)
            this@ResultsManager(simulationStartTime, simulationDuration, simulationStepSize, patient, primaryController, secondaryController);
        end
    end
    
    methods(Access = public)
        plotResults(this, title, grayscale)
    end
    
end
