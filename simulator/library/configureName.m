function options = configureName(className, lastOptions)
%CONFIGURENAME  Input dialog box for a name.
%   OPTIONS = CONFIGURENAME(CLASSNAME, LASTOPTIONS) returns a struct
%   OPTIONS containing the NAME field or an empty matrix on failure.
%   CLASSNAME is the name of the class being configured. LASTOPTIONS is a
%   struct that contains the default NAME field to use in the input dialog
%   box.
%
%   See also INPUTDLG.

prompt = {'Name:'};
dlgTitle = ['Configure ', className];
numLines = 1;
defaultAns = {lastOptions.name};
opt = struct();
opt.Resize = 'on';
response = inputdlg(prompt, dlgTitle, numLines, defaultAns, opt);

options = [];
if ~isempty(response)
    options.name = response{1};
end

end
