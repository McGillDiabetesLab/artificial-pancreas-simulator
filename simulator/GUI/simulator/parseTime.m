function time = parseTime(str)
%PARSETIME  Parse a time string.
%   TIME = PARSETIME(STR) parses a time string in the DD HH:MM format and
%   returns the number of minutes represented by the time string.

%% Check number of input arguments.
narginchk(1, 1);

%% Parse input arguments.
p = inputParser;
addRequired(p, 'str', @ischar);
parse(p, str);

%% Parse time string.
time = [];
tokens = regexp(str, '([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)', 'tokens');
if numel(tokens) == 1
    time = str2double(tokens{1}{1});
elseif numel(tokens) == 2
    time = str2double(tokens{2}{1});
    time = time + 60 .* str2double(tokens{1}{1});
elseif numel(tokens) == 3
    time = str2double(tokens{3}{1});
    time = time + 60 .* str2double(tokens{2}{1});
    time = time + 24 .* 60 .* str2double(tokens{1}{1});
end

end

