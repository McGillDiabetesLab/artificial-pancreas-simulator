function filename = getConfigurationFilename()
%GETCONFIGURATIONFILENAME  Get the name of the user's configuration file.

filename = '.config.mat';

% Copy default config file if no configuration.
if exist(filename, 'file') ~= 2
    filepath = fileparts(which('default.config.mat'));
    copyfile(which('default.config.mat'), [filepath, '\..\', filename])
end

end

