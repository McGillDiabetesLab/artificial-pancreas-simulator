function classes = loadClasses(directoryName)
%LOADCLASSES  Load the classes in the given directory.
%   CLASSES = LOADCLASSES(DIRECTORYNAME) searches the program paths for
%   classes that are contained in a directory with the given name. These
%   classes are identified as directories starting with the @ character.

classes = {};
paths = getLibraryPaths();
for i = 1:numel(paths)
    directory = dir(strcat(paths{i}, filesep, directoryName));
    for index = 1:numel(directory)
        filename = directory(index).name;
        startIndex = regexp(filename, '^@.*$');
        if startIndex == 1
            classes{end+1} = extractAfter(filename, 1);
        end
    end
end

end

