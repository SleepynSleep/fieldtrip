function varargout = wxyz_color(varargin)
% WXYZ_COLOR
% ================================================================
% Usage:
%   c = wxyz_color;             return 1st colorlist;
%   c = wxyz_color();           return 1st colorlist;
%   c = wxyz_color([], 1:6);    return 1:6 color of 1st colorlist;
%   c = wxyz_color(2);          return 2nd colorlist;
%   c = wxyz_color(2, 1:6);     return 1:6 color of 2nd colorlist;
%   c = wxyz_color('all');      return all colorlists;
%   c = wxyz_color('draw');     return and draw all colorlists;
% ================================================================
% @author: wxyz. 2024/09/29.
wxyz_cdata = importdata('wxyz_cdata.mat');

if nargin == 0 % default is 1st
    ctype = 1; cnum = [];
elseif nargin == 1
    if isnumeric(varargin{1})
        ctype = varargin{1}; cnum = [];
    elseif strcmpi('all', varargin{1})
        varargout{1} = wxyz_cdata.Color;
        return;
    elseif strcmpi('draw', varargin{1})
        varargout{1} = wxyz_cdata.Color;
        for i = 1:numel(wxyz_cdata.Name)
            clist = wxyz_cdata.Color(wxyz_cdata.PackageInd == i);
            cNames = wxyz_cdata.Key(wxyz_cdata.PackageInd == i);
            fig = drawAllColor(clist, cNames, wxyz_cdata.Key);
            % print(fig, strcat('D:\MATLAB\R2023b\toolbox\fieldtrip\wxyz\color\', '_', num2str(i), '_', wxyz_cdata.Name{i}, '.png'), '-dpng', '-r300', '-image');
            % close(fig);
        end
        return;
    end
elseif nargin == 2
    if isnumeric(varargin{1})
        ctype = varargin{1};
    else
        ctype = 1;
    end
    cnum = varargin{2};
end
if ~isempty(ctype)
    varargout{1} = wxyz_cdata.Color{ctype}./255;
    N = size(varargout{1}, 1);
    if isempty(cnum) % No selection of given color
    else % Selection of given color
        varargout{1} = varargout{1}(mod(cnum-1, N)+1, :);
        varargout{1} = varargout{1}.*(.9.^(floor((cnum-1)./N).'));
    end
end

%% SUBFUNCTION
function fig = drawAllColor(cstruct, cNames, allNames)
    numCs = length(cstruct);
    numRows = 25;
    numCols = ceil(numCs / numRows);
    [fig, hTiled] = wxyz_figure(numRows, numCols, 'Position', [0 100 500*numCols 1000]);
    set(hTiled, 'TileIndexing', 'columnmajor');
    for i = 1:numCs
        nexttile;
        c=cstruct{i}/255;
        imagesc(1:256);
        colormap(gca, c);
        set(gca, 'ytick', [], 'xtick', []);
        cmapidx = find(strcmpi(allNames, cNames{i}));
        ylabel(strcat(['[', num2str(cmapidx), ']'], {32}, cNames{i}(strfind(cNames{i}, ':')+2:end)), 'FontSize', 12, 'Interpreter', 'none',...
            'Rotation', 0, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
        axis tight;
        % axis off;
    end
    wxyz_decorFigure(fig);