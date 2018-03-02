function str = formatTime(time, alwaysShowDay)
%FORMATTIME  Format the given time.
%   STR = FORMATTIME(TIME, ALWAYSSHOWDAY) returns a string of the form
%   DD HH:MM that represents the given time. TIME is given in minutes.
%   ALWAYSSHOWDAY is a flag that controls whether the DD part of the format
%   string should appear even if the day is zero.

dd = time ./ (24 .* 60);
dd = dd - rem(dd, 1);
time = time - 24 .* 60 .* dd;

hh = time ./ 60;
hh = hh - rem(hh, 1);
time = time - 60 .* hh;

mm = time;

if dd > 0 || alwaysShowDay
    str = [num2str(dd), ' ', num2str(hh), ':', sprintf('%02d', mm)];
else
    str = [num2str(hh), ':', sprintf('%02d', mm)];
end

end

