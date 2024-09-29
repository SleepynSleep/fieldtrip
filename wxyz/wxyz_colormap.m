function varargout = wxyz_colormap(varargin)
% WXYZ_COLOR
% ================================================================
% Usage:
%   cmap = wxyz_colormap;             return 1st colormap;
%   cmap = wxyz_colormap();           return 1st colormap;
%   cmap = wxyz_colormap([], 6);      return 1st colormap but only use 6 level;
%   cmap = wxyz_colormap(2);          return 2nd colormap;
%   cmap = wxyz_colormap(2, 6);       return 2nd colormap but only use 6 level;
%   cmap = wxyz_colormap('all');      return all colormaps;
%   cmap = wxyz_colormap('draw');     return and draw all colormaps;
% ================================================================
% @author: wxyz. 2024/09/29.
wxyz_cmapdata = importdata('wxyz_cmapdata.mat');
cmapdata = [wxyz_cmapdata.colormap(:).Colors];

if nargin == 0
    ctype = 'wxyz_1'; cnum = 256;
elseif nargin == 1
    ctype = varargin{1}; cnum = 256;
elseif nargin == 2
    if ~isempty(varargin{1})
        ctype = varargin{1}; 
    else
        ctype = 1;
    end
    cnum = varargin{2};
end

if isnumeric(ctype)
    cmap = cmapdata{ctype};
else
    if strcmpi('all', ctype)
        varargout{1} = cmapdata;
        return;
    elseif strcmpi('draw', ctype)
        varargout{1} = cmapdata;
        for i = 1:numel(wxyz_cmapdata.colormap)
            fig = drawAllColorMap(wxyz_cmapdata.colormap(i), wxyz_cmapdata.fullNames);
            % print(fig, fullfile(strcat('D:\MATLAB\R2023b\toolbox\fieldtrip\wxyz\colormap\', wxyz_cmapdata.colormap(i).Type, '.png')), '-dpng', '-r600', '-image');
        end
        return;
    else
        cpos = strcmpi(ctype, wxyz_cmapdata.fullNames);
        cmap = cmapdata{cpos};
    end
end
if cnum ~= 256
    ci = 1:256;
    cq = linspace(1, 256, cnum);
    cmap = [interp1(ci, cmap(:,1), cq, 'linear')',...
            interp1(ci, cmap(:,2), cq, 'linear')',...
            interp1(ci, cmap(:,3), cq, 'linear')'];
end
varargout{1} = cmap;

%% SUBFUNCTION
function fig = drawAllColorMap(cmapstruct, cmapNames)
    cmapList = [cmapstruct.Colors];
    numCmaps = length(cmapList);
    numRows = ceil(sqrt(numCmaps))-1;
    numCols = ceil(numCmaps / numRows);
    if numCols < 7
        numCols = 7;
        numRows = 5;
    end
    fig = wxyz_figure(numRows, numCols, 'Position', [0 100 2000 500]);
    for i = 1:numCmaps
        nexttile;
        cmap=cmapList{i};
        imagesc(1:256);
        colormap(gca, cmap);
        set(gca, 'ytick', [], 'xtick', []);
        cmapidx = find(strcmpi(cmapstruct.Names{i}, cmapNames));
        title(strcat(['[', num2str(cmapidx), ']-'], cmapstruct.Names{i}), 'FontSize', 12, 'Interpreter', 'none');
        axis tight;
        % axis off;
    end
    wxyz_decorFigure(fig);
