classdef for_progressbar < handle
    %FOR_PROGRESSBAR  Progress bar suitable for single-process computation.
    %   This class subscribes to the same interface as the
    %   parfor_progressbar class but is better suited to
    %   sequential computation as it does not access any files.
    %
    %   See also PARFOR_PROGRESSBAR.
    
    properties(SetAccess = protected, GetAccess = public)
        wbh; % Waitbar figure object handle
        Nmax; % Total number of iterations expected before completion
        Nitr; % Number of iterations completed so far
    end
    
    methods
        function this = for_progressbar(Nmax, varargin)
            % Create a new progress bar with Nmax iterations before completion.
            
            this.wbh = waitbar(0, varargin{:});
            this.Nmax = Nmax;
            this.Nitr = 0;
        end
        
        function delete(this)
            this.close();
        end
        
        function close(this)
            % Close the progress bar and clean up internal state.
            
            if ishandle(this.wbh)
                close(this.wbh);
            end
            this.wbh = [];
        end
        
        function iterate(this, Nitr)
            % Update the progress bar by Nitr iterations (or 1 if not specified).
            
            if nargin < 2
                Nitr = 1;
            end
            
            this.Nitr = this.Nitr + Nitr;
            percent = this.Nitr ./ this.Nmax;
            this.wbh = waitbar(percent, this.wbh);
        end
    end
    
end

