function configurePaths(directory)
%CONFIGUREPATHS  Configure the simulator's paths.
%   CONFIGUREPATHS(DIRECTORY) configures the simulator's paths given the
%   simulator's top level directory. DIRECTORY is an optional argument that
%   defaults to the current directory.

if ~exist('directory', 'var')
    directory = '.';
end

addpath(genpath([directory, filesep, 'simulator']));

paths = getLibraryPaths();
for i = 1:numel(paths)
    addpath(genpath([directory, filesep, paths{i}]));
end

end
