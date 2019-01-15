function plotTracerInfo(this, figureTitle, grayscale)

if nargin < 4
    grayscale = false;
end

grid on;
hold on;

%colours
if grayscale
    red = rgb2gray([255, 0, 0]/255);
    green = rgb2gray([0, 255, 0]/255);
    blue = rgb2gray([0, 0, 255]/255);
    orange = rgb2gray([155, 100, 0]/255);
else
    red = [255, 0, 0] / 255;
    green = [62, 188, 35] / 255;
    blue = [0, 99, 198] / 255;
    orange = [155, 100, 0] / 255;
end

%% Get data
utime = cell2mat(this.tracerMeasurementTimes);
uval = cell2mat(this.tracerMeasurements);
if ~isempty(uval)
    plasmaGlucose = [uval.plasmaGlucose]*1e-3;
    plasmaInsulin = [uval.plasmaInsulin];
    rateGutAbsorption = [uval.rateGutAbsorption]*60*1e-3;
end

% on the right axis
yyaxis right
cla;
if ~isempty(utime)
    INS_PLASMA = plot(utime, plasmaInsulin, ...
        'color', blue, ...
        'linewidth', 2.5, ...
        'Marker', 'none');
end

% set up right y axis
ylim([0, 100]);
ylabel('Plasema Insulin (mU/L)', 'color', 'k');

% on the left axis
yyaxis left
cla;

% plot Glucose
GLUCOSE_PLASMA = plot(utime, plasmaGlucose, ...
    'color', red, ...
    'linestyle', '-', ...
    'linewidth', 2.5, ...
    'Marker', 'none');


% plot Meals
RATE_GUT = plot(utime, rateGutAbsorption, ...
    'color', orange, ...
    'linestyle', '-', ...
    'linewidth', 2.5, ...
    'Marker', 'none');

% set up axis
ax = gca;
if this.simulationDuration < 18 * 60
    sTick = 1 * 60;
elseif this.simulationDuration < 3 * 24 * 60
    sTick = 4 * 60;
else
    sTick = 12 * 60;
end
ax.XTick = sTick * floor((this.simulationStartTime)/(sTick)):sTick:sTick * ceil((this.simulationStartTime + this.simulationDuration)/(sTick));
ax.XTickLabel = [num2str(mod((sTick / 60 * floor((this.simulationStartTime)/(sTick)):sTick / 60:sTick / 60 * ceil((this.simulationStartTime + this.simulationDuration)/(sTick))), 24)'), repmat(':00', length(sTick/60*floor((this.simulationStartTime)/(sTick)):sTick/60:sTick/60*ceil((this.simulationStartTime + this.simulationDuration)/(sTick))), 1)];

set(gca, 'FontName', 'Helvetica', 'FontWeight', 'bold', 'linewidth', 2.0);
ax.TickDir = 'out';
ax.XAxis.Color = 'k';
for k = 1:length(ax.YAxis)
    ax.YAxis(k).Color = 'k';
    ax.YAxis(k).FontSize = 14;
end
ax.XAxis.FontSize = 14;
xlim([this.simulationStartTime - 40, this.simulationStartTime + this.simulationDuration + 40]);
ylim([0, 5]);
xlabel('Time (HH:MM)');
ylabel(sprintf('plasma Glucose (10^3 umol/Kg) \n& Gut Absorption (10^3 umol/Kg/h)'));

ax.YGrid = 'off';
ax.XGrid = 'off';

legendHandlers = [];
legendTitles = {};

if exist('GLUCOSE_PLASMA', 'var') > 0 && ~isempty(GLUCOSE_PLASMA)
    legendHandlers(end+1) = GLUCOSE_PLASMA;
    legendTitles{end+1} = 'Plasma Glucose';
end
if exist('INS_PLASMA', 'var') > 0
    legendHandlers(end+1) = INS_PLASMA;
    legendTitles{end+1} = 'Plasma Insulin';
end
if exist('RATE_GUT', 'var') > 0
    legendHandlers(end+1) = RATE_GUT;
    legendTitles{end+1} = 'Gut Absorption';
end
if ~isempty(legendHandlers)
    legend(legendHandlers, legendTitles, 'location', 'bestoutside', 'Interpreter', 'none');
    legend boxon;
end
lgd = legend(legendHandlers, legendTitles, 'location', 'best', 'FontSize', 16);
legend boxon;
drawnow
lgd.Location = 'none';