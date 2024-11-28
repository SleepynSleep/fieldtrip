function [hbar, hlgd] = wxyz_barscatterplot(data, varargin) % dat, err, lgd, xaxistick, yaxislabel, gcatitle, color, isPlot0err)

% @author: wxyz. 2024/11/01.

% data: m*n*k. m->group, n->samples, k->conditions per group.

% Code implementation section
% Everything is added to the current figure
holdflag = ishold;
if ~holdflag
  hold on
end

% Set variables
opt                 = [];
opt.data            = data;

% Get nGroup and nCond
if ndims(opt.data) ~= 3
    error('Data or Error data input should be 3d.');
end
opt.nGroup          = size(opt.data, 1);
opt.nSamp           = size(opt.data, 2);
opt.nCond           = size(opt.data, 3);

% Default value
opt.legend          = wxyz_getopt(varargin, 'legend',       '');
opt.showlegend      = wxyz_getopt(varargin, 'showlegend',   true);
opt.xtick           = wxyz_getopt(varargin, 'xtick',        '');
opt.xlabel          = wxyz_getopt(varargin, 'xlabel',       '');
opt.ylabel          = wxyz_getopt(varargin, 'ylabel',       '');
opt.title           = wxyz_getopt(varargin, 'title',        '');
opt.show0err        = wxyz_getopt(varargin, 'show0err',     false);
opt.errtype         = wxyz_getopt(varargin, 'errortype',    'std'); % 'std' or 'sem'
opt.BarWidth        = wxyz_getopt(varargin, 'BarWidth',     1);
opt.facecolor       = wxyz_getopt(varargin, 'facecolor',    [0.5 0.5 0.5]);
opt.facealpha       = wxyz_getopt(varargin, 'facealpha',    1);
opt.edgecolor       = wxyz_getopt(varargin, 'edgecolor',    'none');
opt.edgealpha       = wxyz_getopt(varargin, 'edgealpha',    1);
opt.marker          = wxyz_getopt(varargin, 'marker',       'o');
opt.markersize      = wxyz_getopt(varargin, 'markersize',   60);
opt.markeredgecolor = wxyz_getopt(varargin, 'markerEdgeColor',  'k');
opt.markerXJitter   = wxyz_getopt(varargin, 'markerXJitter',    0.15);
opt.showmarker      = wxyz_getopt(varargin, 'showmarker',   false);
opt.errBarOri       = wxyz_getopt(varargin, 'errBarOri',    'vertical');
opt.errBarStyle     = wxyz_getopt(varargin, 'errBarStyle',  'none');
opt.errBarWidth     = wxyz_getopt(varargin, 'errBarWidth',  2);
opt.errBarColor     = wxyz_getopt(varargin, 'errBarColor',  'k');
opt.errBarCapSize   = wxyz_getopt(varargin, 'errBarCapSize', 6);

if opt.nGroup ~= 1 && opt.nSamp == 1 % Swap nGroup and nSamp
    [opt.nGroup, opt.nSamp] = deal(opt.nSamp, opt.nGroup);
end

% Draw bar, scatter, errorbar
meanData = squeeze(mean(opt.data, 2));
hbar = bar(meanData, 'FaceAlpha', opt.facealpha, 'EdgeColor', opt.edgecolor, 'EdgeAlpha', opt.edgealpha, 'BarWidth', opt.BarWidth); % draw bar
for h = 1:numel(hbar)
    hbar(h).FaceColor = opt.facecolor(h, :);
    tmpX = hbar(h).XEndPoints.'*ones(1, size(opt.data, 2));
    tmpY = squeeze(opt.data(:, :, h));
    avg = meanData(:, h);
    if strcmpi(opt.errtype, 'std')
        err = std(tmpY, 0, 2);
    elseif strcmpi(opt.errtype, 'sem')
        err = std(tmpY, 0, 2)/sqrt(opt.nSamp);
    else
        error('Error type should be ''std'' or ''sem''');
    end
    if opt.showmarker
        scatter(tmpX(:), tmpY(:), opt.markersize, 'filled', opt.marker, 'MarkerEdgeColor', opt.markeredgecolor,...
            'CData', opt.facecolor(h, :), 'XJitter', 'rand', 'XJitterWidth', opt.markerXJitter); % draw data scatter
    end
    % draw errorbar
    if opt.show0err
        errorbar(hbar(h).XEndPoints, avg, err, opt.errBarOri,...
            'LineStyle', opt.errBarStyle, 'LineWidth', opt.errBarWidth, 'Color', opt.errBarColor, 'CapSize', opt.errBarCapSize);
    else
        erridx = err~=0;
        errorbar(hbar(h).XEndPoints(erridx), avg(erridx), err(erridx), opt.errBarOri,...
            'LineStyle', opt.errBarStyle, 'LineWidth', opt.errBarWidth, 'Color', opt.errBarColor, 'CapSize', opt.errBarCapSize);
    end
end
clear avg err

% Update xtick, xlabel, ylabel
xticklabels(opt.xtick);
xlabel(opt.xlabel);
ylabel(opt.ylabel);

% Update legend
if opt.showlegend
    hlgd = legend(hbar, opt.legend);
end

