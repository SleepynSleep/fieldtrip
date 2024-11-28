function wxyz_decorFigure(hFig, varargin)
% WXYZ_DECORFIGURE This function implements a figure that creates a tiledlayout
% containing the specified number of grids. 
% 
% This function takes a handle to figure and the corresponding arguments to
% modify the figure.
% 
% hFig  - the first input parameter, should be a positive integer.
% 
% Other arguments should come in key-value pairs and can include
% 'FontSize', 'FontName', 'FontWeight', 'FontScale', 'BoxWidth', 'Box', 'LegendSize'.
%
% example:
%   wxyz_decorFigure(hFig, 'FontSize', 12, 'Box', 'off');
% 
% Author: wxyz
% Version: 1.0
% Last revision date : 2024/11/28

% Code implementation section
opt             = [];
opt.FontSize    = wxyz_getopt(varargin, 'FontSize',     12);
opt.FontName    = wxyz_getopt(varargin, 'FontName',     'Calibri');
opt.FontWeight  = wxyz_getopt(varargin, 'FontWeight',   'bold');
opt.FontScale   = wxyz_getopt(varargin, 'FontScale',    1.4);
opt.BoxWidth    = wxyz_getopt(varargin, 'BoxWidth',     1);
opt.Box         = wxyz_getopt(varargin, 'Box',          'on');
opt.LegendSize  = wxyz_getopt(varargin, 'LegendSize',   [12 12]);

%% Figure Font
set(hFig, 'Color', 'w');
set(findobj(hFig, 'Type', 'Axes'), ...
    'FontName', opt.FontName,...
    'FontSize', opt.FontSize,...
    'FontWeight', opt.FontWeight,...
    'TitleFontWeight', opt.FontWeight, ...
    'LabelFontSizeMultiplier', opt.FontScale,...
    'TitleFontSizeMultiplier', opt.FontScale);

if ~isempty(findobj(hFig, 'Type', 'Legend'))
    set(findobj(hFig, 'Type', 'Legend'), 'FontSize', opt.FontSize*1, 'FontWeight', opt.FontWeight, 'ItemTokenSize', opt.LegendSize);
end

if ~isempty(findobj(hFig, 'Type', 'Text'))
    set(findobj(hFig, 'Type', 'Text'), 'FontName', opt.FontName, 'FontSize', opt.FontSize*1);
end

if ~isempty(findobj(hFig, 'Type', 'ColorBar'))
    set(findobj(hFig, 'Type', 'ColorBar'), 'FontSize', opt.FontSize*0.9);
    cb = findall(hFig, 'Type', 'Colorbar');
    for c = 1:numel(cb)
        set(cb(c).Label, 'FontName', opt.FontName, 'FontSize', opt.FontSize, 'FontWeight', opt.FontWeight, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'cap');
    end
end

if ~isempty(findobj(hFig, 'Type', 'tiledlayout'))
    set(findobj(hFig, 'Type', 'tiledlayout').Title, 'FontSize', opt.FontSize*opt.FontScale,...
        'FontName', opt.FontName, 'FontWeight', opt.FontWeight);
end
if ~isempty(findall(hFig, 'Type', 'textbox')) % Annotation
    set(findall(hFig, 'Type', 'textbox'), 'FontSize', opt.FontSize*opt.FontScale,...
        'FontName', opt.FontName, 'FontWeight', opt.FontWeight, 'FitBoxToText', true, 'EdgeColor', 'none');
end

%% Axis Box
set(findobj(hFig, 'Type', 'Axes'), 'Box', opt.Box); % axes box
set(findobj(hFig, 'Type', 'Axes'), 'LineWidth', opt.BoxWidth); % axes box line


