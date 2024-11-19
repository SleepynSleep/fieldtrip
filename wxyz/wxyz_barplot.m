function [hbar, hlgd] = wxyz_barplot(data, err, color, varargin) % dat, err, lgd, xaxistick, yaxislabel, gcatitle, color, isPlot0err)
% WXYZ_BARPLOT This function implements the ability to plot bar graphs and
% error bars.
% 
% This function takes data, err and color, as well as other arguments, and 
% then returns handles to the drawn bars and legend.
% 
% data  - used to plot the bars should be an array of m*n, where m is the
%         group and n is the number of conditions in each group. 
% err   - used to plot the error bars has the same dimensions as data.
% color - used for plotting, which should be a matrix of n*3.
%
% Other arguments should come in key-value pairs and can include 'legend',
% 'xtick', 'xlabel', 'ylabel', 'title', 'show0err', 'BarWidth',
% 'errBarStyle', 'errBarWidth', 'errBarColor', 'errBarCapSize',
% 'facealpha', 'edgecolor', 'edgealpha'.
% 
% hbar  - the created bar plot handle.
% hlgd  - the created elgend handle.
%
% example:
%   [hbar, hlgd] = wxyz_barplot(data, err, color, 'xtick', {'G1', 'G2', 'G3'});
% 
% @author: wxyz. 2024/11/01.

% data: m*n. m->group, n->condition per group.

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
opt.color           = color;

% Get nGroup and nCond
opt.nGroup          = size(opt.data, 1);
opt.nCond           = size(opt.data, 2);

% Default value
opt.legend          = wxyz_getopt(varargin, 'legend', '');
% opt.legendmode      = wxyz_getopt(varargin, 'legendmode', 'manual'); % 'manual' or 'auto'
% opt.showlegend      = wxyz_getopt(varargin, 'showlegend', '');
opt.xtick           = wxyz_getopt(varargin, 'xtick', '');
% opt.xtickmode       = wxyz_getopt(varargin, 'xtickmode', 'manual'); % 'manual' or 'auto'
opt.xlabel          = wxyz_getopt(varargin, 'xlabel', '');
opt.ylabel          = wxyz_getopt(varargin, 'ylabel', '');
opt.title           = wxyz_getopt(varargin, 'title', '');
opt.show0err        = wxyz_getopt(varargin, 'show0err', true);
opt.BarWidth        = wxyz_getopt(varargin, 'BarWidth', 1);
opt.errBarStyle     = wxyz_getopt(varargin, 'errBarStyle', '-');
opt.errBarWidth     = wxyz_getopt(varargin, 'errBarWidth', 1);
opt.errBarColor     = wxyz_getopt(varargin, 'errBarColor', 'k');
opt.errBarCapSize   = wxyz_getopt(varargin, 'errBarCapSize', 6);
% opt.facecolor       = wxyz_getopt(varargin, 'facecolor', 'none');
opt.facealpha       = wxyz_getopt(varargin, 'facealpha', 1);
opt.edgecolor       = wxyz_getopt(varargin, 'edgecolor', 'none');
opt.edgealpha       = wxyz_getopt(varargin, 'edgealpha', 1);
% opt.showData        = wxyz_getopt(varargin, 'showData', false);

if size(opt.color, 1) ~= size(opt.data, 1) && size(opt.color, 1) ~= size(opt.data, 2)
    error('Color number should be euqal with bar number.');
end

if opt.nGroup ~= 1 && opt.nCond == 1 % Swap nGroup and nCond
    [opt.nGroup, opt.nCond] = deal(opt.nCond, opt.nGroup);
end

% Draw bar and errbar
if opt.nGroup == 1 % only one group
    hbar = gobjects(1, opt.nCond);
    for i = 1:opt.nCond
        hbar(i) = bar(i, opt.data(i), 'BarWidth', opt.BarWidth, 'EdgeColor', opt.edgecolor);
        hbar(i).FaceColor = opt.color(i, :);
        hbar(i).FaceAlpha = opt.facealpha;
        if ~(opt.err(i) == 0 && ~opt.show0err)
            errorbar(hbar(i).XEndPoints, hbar(i).YEndPoints, opt.err(i), 'Color', opt.errBarColor, 'CapSize', opt.errBarCapSize, 'LineStyle', 'none', 'LineWidth', opt.errBarWidth);
        end
    end
    if isempty(opt.xtick)
        set(gca, 'XTick', []);
    else
        set(gca, 'XTick', 1:opt.nCond, 'XTickLabel', opt.xtick);
    end
else % more than one group
    hbar = bar(opt.data, 'BarWidth', opt.BarWidth, 'EdgeColor', opt.edgecolor);
    for i = 1:opt.nCond
        hbar(i).FaceColor = opt.color(i, :);
        hbar(i).FaceAlpha = opt.facealpha;
        if opt.show0err
            errorbar(hbar(i).XEndPoints, hbar(i).YEndPoints, opt.err(:, i), 'Color', opt.errBarColor, 'CapSize', opt.errBarCapSize, 'LineStyle', 'none', 'LineWidth', opt.errBarWidth);
        else
            err = opt.err(:, i);
            errorbar(hbar(i).XEndPoints(err~=0), hbar(i).YEndPoints(err~=0), err(err~=0), 'Color', opt.errBarColor, 'CapSize', opt.errBarCapSize, 'LineStyle', 'none', 'LineWidth', opt.errBarWidth);
        end
    end
    if isempty(opt.xtick)
        set(gca, 'XTick', []);
    else
        set(gca, 'XTick', 1:opt.nGroup, 'XTickLabel', opt.xtick);
    end
end

% Update legend
if ~isempty(opt.legend)
    hlgd = legend(hbar, opt.legend);
end

xlabel(opt.xlabel);
ylabel(opt.ylabel);
title(opt.title);

if ~holdflag
  hold off
end

if ~nargout
  clear hbar hlgd
end