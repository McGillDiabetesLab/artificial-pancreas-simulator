function plotSummary(resultsManagers)
% sort Results per patient name & controller name
results = containers.Map();
for rm = 1:numel(resultsManagers)
    name = sprintf('%s-%s', class(resultsManagers{rm}.patient), resultsManagers{rm}.primaryController.name);
    if(results.isKey(name))
        results(name) = [results(name) resultsManagers{rm}];
    else
        results(name) = resultsManagers{rm};
    end
end

% colours
red = [255, 0, 0] / 255;
green = [62, 188, 35] / 255;
blue = [0, 99, 198] / 255;
orange = [255, 0, 0] / 255;

% plot each combination
for key = keys(results)
    keyRes = results(key{1});
    
    figID = mod(prod(double(key{1})), 1000);
    this = keyRes(1);
    
    if ishandle(figID)
        h = figure(figID);
        
        set(h, 'name', sprintf('Summary of %d %s with %s', ...
            length(keyRes), class(this.patient), this.primaryController.name),...
            'numbertitle','off',...
            'defaultAxesColorOrder',[[1 0 0]; [0 0 1]]);
    else
        h = figure(figID);
        set(h, 'name', sprintf('Summary of %d %s with %s', ...
            length(keyRes), this.patient.name, this.primaryController.name),...
            'Units', 'normalized', ...
            'Position', [0.1 0.1 0.8 0.7],...
            'numbertitle','off',...
            'defaultAxesColorOrder',[[1 0 0]; [0 0 1]]);
    end
    
    clf;
    hold on;
    
    %% Get data
    ytime = cell2mat(this.glucoseMeasurementTimes);
    utime = cell2mat(this.primaryInfusionTimes);
    yvalAll = nan(length(keyRes), this.simulationDuration/this.simulationStepSize + 1);
    meanGlucose = nan(length(keyRes), 1);
    percInRange = nan(length(keyRes), 1);
    hypoCount = nan(length(keyRes), 1);
    basalInsulinAll = nan(length(keyRes), this.simulationDuration/this.simulationStepSize);
    bolusInsulin = nan(length(keyRes), this.simulationDuration/this.simulationStepSize);
    bolusGlucagon = nan(length(keyRes), this.simulationDuration/this.simulationStepSize);
    meals = nan(length(keyRes), this.simulationDuration/this.simulationStepSize);
    for i = 1: length(keyRes)
        yvalAll(i, :) = cell2mat(keyRes(i).glucoseMeasurements);
        percInRange(i) = sum(yvalAll(i, :) >= 3.9 & yvalAll(i, :) < 10.0)/size(yvalAll, 2);
        meanGlucose(i) = mean(yvalAll(i, :));
        uval = cell2mat(keyRes(i).primaryInfusions);
        basalInsulinAll(i, :) = [uval.basalInsulin];
        bolusInsulin(i, :) = [uval.bolusInsulin];
        if(isfield(uval, 'bolusGlucagon'))
            bolusGlucagon(i, :) = [uval.bolusGlucagon];
        else
            bolusGlucagon(i, :) = zeros(size([uval.bolusInsulin]));
        end
        
        meals(i, :) = keyRes(i).patient.getMeal(utime).value + keyRes(i).patient.getTreatment(utime);
        hypoCount(i) = sum(full(keyRes(i).patient.getTreatment(utime)) > 0);
    end
    yval = prctile(yvalAll,[25 50 75],1);
    basalInsulin = prctile(basalInsulinAll,[25 50 75],1);
    %% Plot all
    title(sprintf('%2.0fh Simulation for %s with %s ',this.simulationDuration/60, class(this.patient), this.primaryController.name),...
        'interpreter', 'none');
    
    % on the right axis
    yyaxis right
    cla;
    time_grade = kron(utime(2:end), [1 1]);
    time_grade(2:end+1) = time_grade;
    time_grade(1) = utime(1);
    basal_grade = kron(basalInsulin(:,1:end-1), [1 1]);
    basal_grade(:, end+1) = basalInsulin(:, end);
    
    maxbasalInsulin = prctile(basalInsulinAll, 95, 1);
    maxbasalInsulin_grade = kron(maxbasalInsulin(:,1:end-1), [1 1]);
    maxbasalInsulin_grade(:, end+1) = maxbasalInsulin(:, end);
    
    minbasalInsulin = prctile(basalInsulinAll, 5, 1);
    minbasalInsulin_grade = kron(minbasalInsulin(:,1:end-1), [1 1]);
    minbasalInsulin_grade(:, end+1) = minbasalInsulin(:, end);
    
    patch([time_grade, fliplr(time_grade)], [maxbasalInsulin_grade fliplr(minbasalInsulin_grade)], [190 190 255]/255, 'FaceAlpha', 0.3, 'LineStyle', 'none');
    patch([time_grade, fliplr(time_grade)], [basal_grade(1,:) fliplr(basal_grade(3,:))], [190 190 255]/255, 'FaceAlpha', 0.7, 'LineStyle', 'none');
    INS_BASAL = plot(time_grade, basal_grade(2, :),...
        'color', blue,...
        'linewidth', 1.6,...
        'Marker', 'none');
    
    % set up right y axis
    ylim([0 10]);
    ylabel('Insulin (U/h)', 'color', 'k');
    
    % on the left axis
    yyaxis left
    cla;
    
    % plot Day & Night indications
    timeDense = ytime(1):0.1:ytime(end);
    plot(timeDense,...
        10.0*(mod(timeDense, 24*60) < 22*60 & mod(timeDense, 24*60) > 7*60) +...
        7.0*(mod(timeDense, 24*60) >= 22*60 | mod(timeDense, 24*60) <= 7*60),...
        '-.k', 'linewidth', 0.8, 'Marker', 'none');
    plot(timeDense, 4.0*ones(size(timeDense)), '-.k', 'linewidth', 0.8, 'Marker', 'none');
    
    % plot Glucose
    maxy = prctile(yvalAll, 95, 1);
    miny = prctile(yvalAll, 5, 1);
    patch([ytime, fliplr(ytime)], [maxy fliplr(miny)], [255 190 190]/255, 'FaceAlpha', 0.3, 'LineStyle', 'none');
    patch([ytime, fliplr(ytime)], [yval(1,:) fliplr(yval(3,:))], [255 190 190]/255, 'FaceAlpha', 0.7, 'LineStyle', 'none');
    GLUCOSE = plot(ytime, yval(2,:),...
        'color', red,...
        'linestyle', '--',...
        'linewidth', 1.3,...
        'Marker', '.',...
        'MarkerSize', 14);
    
    densityBolus = sum(bolusInsulin>0, 1)/size(bolusInsulin,1);
    for n = 1:1:size(densityBolus, 2)
        if(densityBolus(n) > 0)
            INS_BOLUS = plot(ytime(n), max(14.5, yval(2,n)+2.5) - 0.25, 'color',blue, 'Marker', 'v', 'MarkerSize', 10*densityBolus(n), 'MarkerEdgeColor', blue, 'MarkerFaceColor',blue);
            if(densityBolus(n) > 0.25)
                text(ytime(n), max(14.5, yval(2,n)+2.5), [num2str(mean(bolusInsulin(bolusInsulin(:,n) > 0,n)), '%.2f') ' U'],'VerticalAlignment', 'bottom' ,'HorizontalAlignment','center', 'Color', blue, 'FontSize', 8, 'FontWeight', 'bold');
            end
        end
    end
    
    densityMeals = sum(meals>0, 1)/size(meals,1);
    for n = 1:1:size(densityMeals, 2)
        if(densityMeals(n)> 0)
            MEALS = plot(ytime(n), max(16, yval(2,n)+4.5) - 0.25, '-', 'color', orange, 'Marker', 'v', 'MarkerSize', 10*densityMeals(n), 'MarkerFaceColor', orange, 'MarkerEdgeColor', orange);
            if(densityMeals(n) > 0.25)
                text(ytime(n), max(16, yval(2,n)+4.5), [num2str(mean(meals(meals(:,n) > 0,n)), '%.1f') ' g'],'VerticalAlignment','bottom','HorizontalAlignment','center', 'Color', orange, 'FontSize', 8, 'FontWeight', 'bold');
            end
        end
    end
    
    % set up axis
    ax = gca;
    if this.simulationDuration < 12*60
        sTick = 1*60;
    elseif this.simulationDuration < 3*24*60
        sTick = 4*60;
    else
        sTick = 12*60;
    end
    ax.XTick = sTick*floor(ytime(1)/(sTick)):sTick:sTick*ceil(ytime(end)/(sTick));
    ax.XTickLabel = [num2str(mod((sTick/60*floor(ytime(1)/(sTick)):sTick/60:sTick/60*ceil(ytime(end)/(sTick))), 24)') repmat(':00',length(sTick/60*floor(ytime(1)/(sTick)):sTick/60:sTick/60*ceil(ytime(end)/(sTick))),1)];
    
    set(gca,'FontWeight','bold','linewidth',1.5);
    ax.TickDir = 'out';
    ax.XAxis.Color = 'k';
    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = 'k';
    xlim([min(ytime)-40 max(ytime)+40]);
    ylim([0 20]);
    xlabel('Time (HH:MM)');
    ylabel('Sensor Glucose (mmol/L)');
    
    annotation('textbox', [0.77, 0.4, 0, 0],...
        'FitBoxToText','on',...
        'string', sprintf(...
        'In Target : %04.2f[%04.2f - %04.2f] %%\n Mean Glucose : %04.2f[%04.2f - %04.2f] (mmol/L)\n Count Hypo : %04.2f[%04.2f - %04.2f]',...
        round(prctile(percInRange, [50, 25, 75])*100,2),...
        round(prctile(meanGlucose, [50, 25, 75]),2),...
        round(prctile(hypoCount, [50, 25, 75]),2)));
    
    legendHandlers = [GLUCOSE, INS_BASAL];
    legendTitles = {'Sensor Glucose', sprintf('Insulin Basal (%s)', this.primaryController.name)};
    
    if exist('INS_BOLUS', 'var') > 0
        legendHandlers(end+1) = INS_BOLUS;
        legendTitles{end+1} = sprintf('Insulin Bolus (%s)', this.primaryController.name);
    end
    if exist('MEALS', 'var') > 0
        legendHandlers(end+1) = MEALS;
        legendTitles{end+1} = 'Meal CHO';
    end
    legend(legendHandlers,legendTitles, 'location', 'bestoutside', 'Interpreter', 'none');
    legend boxon;
    drawnow
end
