function paths = getLibraryPaths()
%GETLIBRARYPATHS  Get the user's library paths.
%   PATHS = GETLIBRARYPATHS() returns a cell array containing the user's
%   library paths. These are directories that contain the user's custom
%   classes and functions to be used with the simulator.

% Custom classes that extend the VirtualPatient abstract class should be
% placed in a folder called @ClassName inside a subdirectory called
% 'virtual-patients', where ClassName is the name of the subclass.

% Custom classes that extend the MealPlan abstract class should be placed
% in a folder called @ClassName inside a subdirectory called 'meal-plans',
% where ClassName is the name of the subclass.

% Custom classes that extend the ExercisePlan abstract class should be
% placed in a folder called @ClassName inside a subdirectory called
% 'exercise-plans', where ClassName is the name of the subclass.

% Custom classes that extend the InfusionController abstract class should
% be placed in a folder called @ClassName inside a subdirectory called
% 'controllers', where ClassName is the name of the subclass.

% Custom classes that extend the ResultsManager abstract class should be
% placed in a folder called @ClassName inside a subdirectory called
% 'results-managers', where ClassName is the name of the subclass.

% To add a library path to the simulator, simply add the path name to
% the PATHS cell array below.
%
% Example: Adding the 'user-library' path:
%
%   paths = { ...
%       'library', ...
%       'user-library', ...
%       };

paths = { ...
    'library', ...
    };

end

