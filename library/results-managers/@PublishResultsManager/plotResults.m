function plotResults(this, figureTitle, grayscale)

if nargin < 4
    grayscale = false;
end

grid on;
hold on;

%colours
if grayscale
    red = rgb2gray([255, 0, 0] / 255);
    green = rgb2gray([0, 255, 0] / 255);
    blue = rgb2gray([0, 0, 255] / 255);
    orange = rgb2gray([255, 0, 0] / 255);
else
    red = [255, 0, 0] / 255;
    green = [62, 188, 35] / 255;
    blue = [0, 99, 198] / 255;
    orange = [255, 0, 0] / 255;
end

%% Get data
ytime = cell2mat(this.glucoseMeasurementTimes);
yval = cell2mat(this.glucoseMeasurements);
utime = cell2mat(this.primaryInfusionTimes);
uval = cell2mat(this.primaryInfusions);
basalInsulin = [];
bolusInsulin = [];
bolusGlucagon = [];
if ~isempty(uval)
    basalInsulin = [uval.basalInsulin];
    bolusInsulin = [uval.bolusInsulin];
    if isfield(uval, 'bolusGlucagon')
        bolusGlucagon = [uval.bolusGlucagon];
    else
        bolusGlucagon = zeros(size(bolusInsulin));
    end
end

meals = this.patient.mealPlan.getMeal(ytime);
usedMeals = this.patient.getMeal(ytime);
treats = this.patient.mealPlan.getTreatment(ytime);
hypoCount = sum(full(treats) > 0);

meals.value = meals.value + treats;
meals.glycemicLoad = meals.glycemicLoad;

exers = this.patient.getExercise(ytime);

prop = this.patient.getProperties();

%% Plot all
title(figureTitle, 'FontSize', 18);

% Treat MDI controllers differently
if ~contains(class(this.primaryController), 'mdi', 'IgnoreCase',true)
    % on the right axis
    yyaxis right
    cla;
    if ~isempty(utime)
        INS_BASAL = stairs([utime, utime(end) + this.simulationStepSize], [basalInsulin, basalInsulin(end)], ...
            'color', blue, ...
            'linewidth', 3.7, ...
            'Marker', 'none');
    end
    
    % set up right y axis
    ylim([0, 24.5/4]);
    yticks([0:1:6])
    if exist('GLUCAGON', 'var') > 0
        ylabel('Insulin (U/h) & Glucagon (0.5xU)', 'color', 'k');
    elseif exist('P_BASAL', 'var') > 0
        ylabel('Insulin/Pramlintide (U/h)', 'color', 'k');
    else
        ylabel('Insulin (U/h)', 'color', 'k');
    end
    
    
    % on the left axis
    yyaxis left
end
cla;

% plot Day & Night indications
timeDense = (this.simulationStartTime):0.1:(this.simulationStartTime + this.simulationDuration);
plot(timeDense, ...
    10.0*(mod(timeDense, 24*60) < 22 * 60 & mod(timeDense, 24*60) > 7 * 60)+ ...
    10.0*(mod(timeDense, 24*60) >= 22 * 60 | mod(timeDense, 24*60) <= 7 * 60), ...
    '--k', 'linewidth', 1.2, 'Marker', 'none');
plot(timeDense, 3.9*ones(size(timeDense)),...
    '--k', 'linewidth', 1.2, 'Marker', 'none');

% plot Glucose
GLUCOSE = plot(ytime, yval, ...
    'color', red, ...
    'linestyle', '--', ...
    'linewidth', 2.7, ...
    'Marker', '.', ...
    'MarkerSize', 27);

% plot Meals
plotted_carbs = zeros(size(ytime));
for n = 1:1:length(ytime)
    if length(meals.value) >= n && meals.value(n) > 0
        MEALS = plot(ytime(n), 21.5,...
            '-', ...
            'color', orange, ...
            'Marker', '^', ...
            'MarkerSize', 17, ...
            'MarkerFaceColor', orange, ...
            'MarkerEdgeColor', orange);
        delta_n = (n - 2:n + 2);
        delta_n(delta_n <= 0 | delta_n > length(ytime)) = [];
        if ~plotted_carbs(n)
            text(ytime(n), 20.2,...
                [num2str(sum(meals.value(delta_n)), '%d'), 'g'], ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center', ...
                'Color', orange, ...
                'FontSize', 15, ...
                'FontWeight', 'bold');
            plotted_carbs(delta_n) = ones(size(delta_n));
        end
    end
end

% plot Used Meals
plotted_carbs = zeros(size(ytime));
for n = 1:1:length(ytime)
    if length(usedMeals.value) >= n && usedMeals.value(n) > 0
        USED_MEALS = plot(ytime(n), 23.5,...
            '-', ...
            'color', 'm', ...
            'Marker', 'o', ...
            'MarkerSize', 17, ...
            'MarkerFaceColor', 'm', ...
            'MarkerEdgeColor', 'm');
        delta_n = (n - 2:n + 2);
        delta_n(delta_n <= 0 | delta_n > length(ytime)) = [];
        if ~plotted_carbs(n)
            text(ytime(n), 22.2,...
                [num2str(sum(usedMeals.value(delta_n)), '%d'), 'g'], ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center', ...
                'Color', 'm', ...
                'FontSize', 15, ...
                'FontWeight', 'bold');
            plotted_carbs(delta_n) = ones(size(delta_n));
        end
    end
end


% plot Insulin Boluses
plotted_i_boluses = zeros(size(utime));
for n = 1:1:length(utime)
    if bolusInsulin(n) > 0
        INS_BOLUS = plot(utime(n), 18.5,...
            '-', ...
            'color', blue, ...
            'Marker', 'v', ...
            'MarkerSize', 17, ...
            'MarkerEdgeColor', blue, ...
            'MarkerFaceColor', blue);
        delta_n = (n - 2:n + 2);
        delta_n(delta_n <= 0 | delta_n > length(utime)) = [];
        if ~plotted_i_boluses(n)
            text(utime(n), 19,...
                [num2str(sum(bolusInsulin(delta_n)), '%.1f'), 'U'], ...
                'VerticalAlignment', 'bottom', ...
                'HorizontalAlignment', 'center', ...
                'Color', blue, ...
                'FontSize', 15, ...
                'FontWeight', 'bold');
            plotted_i_boluses(delta_n) = ones(size(delta_n));
        end
    end
end

% plot Insulin Basal for MDI controllers
if contains(class(this.primaryController), 'mdi', 'IgnoreCase',true)
    bsaslDose = round(2*prop.pumpBasals.value*24)/2;
    INS_BASAL = plot(utime((21*60 - mod(this.simulationStartTime, 1440))/this.simulationStepSize + 1), 18.5,...
        '-', ...
        'color', blue, ...
        'Marker', 'o', ...
        'MarkerSize', 17, ...
        'MarkerEdgeColor', blue, ...
        'MarkerFaceColor', blue);
    text(utime((21*60 - mod(this.simulationStartTime, 1440))/this.simulationStepSize + 1), 19,...
        [num2str(bsaslDose, '%.1f'), 'U'], ...
        'VerticalAlignment', 'bottom', ...
        'HorizontalAlignment', 'center', ...
        'Color', blue, ...
        'FontSize', 15, ...
        'FontWeight', 'bold');
end

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
ylim([0, 24.5]);
yticks([0:2:24])
xlabel('Time (HH:MM)');
ylabel('Sensor Glucose (mmol/L)');

ax.YGrid = 'off';
ax.XGrid = 'off';

legendHandlers = [];
legendTitles = {};

if exist('GLUCOSE', 'var') > 0 && ~isempty(GLUCOSE)
    legendHandlers(end+1) = GLUCOSE;
    legendTitles{end+1} = 'Sensor Glucose';
end
if exist('GLUCAGON', 'var') > 0
    legendHandlers(end+1) = GLUCAGON;
    legendTitles{end+1} = 'Glucagon Bolus';
end
if exist('INS_BASAL', 'var') > 0
    legendHandlers(end+1) = INS_BASAL;
    legendTitles{end+1} = 'Insulin Basal';
end
if exist('INS_BOLUS', 'var') > 0
    legendHandlers(end+1) = INS_BOLUS;
    legendTitles{end+1} = 'Insulin Bolus';
end
if exist('MEALS', 'var') > 0
    legendHandlers(end+1) = MEALS;
    legendTitles{end+1} = 'Meal CHO';
end
if exist('USED_MEALS', 'var') > 0
    legendHandlers(end+1) = USED_MEALS;
    legendTitles{end+1} = 'Bolused CHO';
end
if exist('EXERS', 'var') > 0
    legendHandlers(end+1) = EXERS;
    legendTitles{end+1} = 'Exercise';
end
if exist('INS_BASAL_OL', 'var') > 0 && ~isempty(INS_BASAL_OL)
    legendHandlers(end+1) = INS_BASAL_OL;
    legendTitles{end+1} = 'Open-Loop Insulin Basal';
end
if ~isempty(legendHandlers)
    legend(legendHandlers, legendTitles, 'location', 'bestoutside', 'Interpreter', 'none');
    legend boxon;
end
lgd = legend(legendHandlers, legendTitles, 'location', 'best', 'FontSize', 16);
legend boxon;
drawnow
lgd.Location = 'none';