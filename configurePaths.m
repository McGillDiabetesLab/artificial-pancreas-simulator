function configurePaths()
%CONFIGUREPATHS  Configure the simulator's paths.

[filepath, ~, ~] = fileparts(mfilename('fullpath'));
addpath(genpath([filepath, filesep, 'simulator']));

paths = getLibraryPaths();
for i = 1:numel(paths)
    addpath(genpath(paths{i}));
end

end
