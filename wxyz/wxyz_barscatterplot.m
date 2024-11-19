function [hbar, hlgd] = wxyz_barscatterplot(data, err, varargin) % dat, err, lgd, xaxistick, yaxislabel, gcatitle, color, isPlot0err)

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
opt.err             = err;

% Get nGroup and nCond
if ndims(opt.data) ~= 3 || ndims(opt.err) ~= 3
    error('Data or Error data input should be 3d.');
end
opt.nGroup          = size(opt.data, 1);
opt.nCond           = size(opt.data, 2);
opt.nSamp           = size(opt.data, 2);

% Default value
opt.legend          = wxyz_getopt(varargin, 'legend',       '');
% opt.legendmode      = wxyz_getopt(varargin, 'legendmode', 'manual'); % 'manual' or 'auto'
% opt.showlegend      = wxyz_getopt(varargin, 'showlegend', '');
opt.xtick           = wxyz_getopt(varargin, 'xtick',        '');
% opt.xtickmode       = wxyz_getopt(varargin, 'xtickmode', 'manual'); % 'manual' or 'auto'
opt.xlabel          = wxyz_getopt(varargin, 'xlabel',       '');
opt.ylabel          = wxyz_getopt(varargin, 'ylabel',       '');
opt.title           = wxyz_getopt(varargin, 'title',        '');
opt.show0err        = wxyz_getopt(varargin, 'show0err',     false);
opt.BarWidth        = wxyz_getopt(varargin, 'BarWidth',     1);
opt.errBarStyle     = wxyz_getopt(varargin, 'errBarStyle',  '-');
opt.errBarWidth     = wxyz_getopt(varargin, 'errBarWidth',  1);
opt.errBarColor     = wxyz_getopt(varargin, 'errBarColor',  'k');
opt.errBarCapSize   = wxyz_getopt(varargin, 'errBarCapSize', 6);
opt.facecolor       = wxyz_getopt(varargin, 'facecolor',    [0.5 0.5 0.5]);
opt.facealpha       = wxyz_getopt(varargin, 'facealpha',    1);
opt.edgecolor       = wxyz_getopt(varargin, 'edgecolor',    'none');
opt.edgealpha       = wxyz_getopt(varargin, 'edgealpha',    1);
opt.marker          = wxyz_getopt(varargin, 'marker',       'o');
opt.markersize      = wxyz_getopt(varargin, 'markersize',   60);
opt.markeredgecolor = wxyz_getopt(varargin, 'markeredgecolor',      'none');
opt.markerXJitter   = wxyz_getopt(varargin, 'markerXJitter', 0.15);
opt.showmarker      = wxyz_getopt(varargin, 'showmarker',   false);

if opt.nGroup ~= 1 && opt.nSamp == 1 % Swap nGroup and nSamp
    [opt.nGroup, opt.nSamp] = deal(opt.nSamp, opt.nGroup);
end

% Draw bar, scatter, errorbar
meanData = squeeze(mean(opt.data, 2));
hbar = bar(meanData, 'FaceAlpha', opt.facealpha, 'EdgeColor', opt.edgecolor, 'EdgeAlpha', opt.edgealpha); % draw bar
for h = 1:numel(hbar)
    hbar(h).FaceColor = opt.facecolor(h, :);
    tmpX = hbar(h).XEndPoints.'*ones(1, size(opt.data, 2));
    tmpY = opt.data(:, :, h);
    if opt.showmarker
        scatter(tmpX(:), tmpY(:), opt.markersize, 'filled', opt.marker, 'MarkerEdgeColor', opt.markeredgecolor,...
            'CData', opt.facecolor(h, :), 'XJitter', 'rand', 'XJitterWidth', opt.markerXJitter); % draw data scatter
    end
    errorbar(hbar(h).XEndPoints, meanData(:, h), std(tmpY, 0, 2), 'vertical',...
        'LineStyle', 'none', 'LineWidth', 1, 'Color', 'k'); % draw errorbar
end

% Update xtick



