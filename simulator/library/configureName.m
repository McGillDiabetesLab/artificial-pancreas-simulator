function options = configureName(lastOptions)
%CONFIGURENAME  Input dialog box for a name.
%   OPTIONS = CONFIGURENAME(LASTOPTIONS) returns a struct OPTIONS
%   containing the NAME field or an empty matrix on failure. LASTOPTIONS is
%   a struct that contains the default NAME field to use in the input
%   dialog box.
%
%   See also INPUTDLG.

prompt = {'Name:'};
dlgTitle = 'Configure';
numLines = 1;
defaultAns = {lastOptions.name};
response = inputdlg(prompt, dlgTitle, numLines, defaultAns);
options = [];
if ~isempty(response)
    options.name = response{1};
end

end

