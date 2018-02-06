function configurePaths()
%CONFIGUREPATHS  Configure the simulator's paths.

addpath(genpath('simulator'));

paths = getLibraryPaths();
for i = 1:numel(paths)
    addpath(genpath(paths{i}));
end

end

