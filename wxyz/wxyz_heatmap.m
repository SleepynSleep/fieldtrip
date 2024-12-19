function [hedge, hface, htext] = wxyz_heatmap(data, varargin)
% wxyz_heatmap
% Copyright (c) 2024, wxyz.
% Input
%   data: N*N matrix.
%   varargin: Some other inputs.
%       format: square/circular/oval/pie/hexagon/auto-square/auto-circular.
%       type:   full/triu/tril/triu0/tril0
%       ...
% Output
%   hedge
%   hface
%   htext: 
% @author: wxyz, 2024/12/16.

%% Code implementation section
% Everything is added to the current figure
holdflag = ishold;
if ~holdflag
  hold on
end

%% Set default variable value
opt                     = [];
opt.colormap            = wxyz_getopt(varargin, 'colormap',     colormap('parula'));
opt.format              = wxyz_getopt(varargin, 'format',       'square'); % square/circular/oval/pie/hexagon/auto-square/auto-circular
opt.type                = wxyz_getopt(varargin, 'type',         'full'); % full/triu/tril/triu0/tril0
opt.edgecolor           = wxyz_getopt(varargin, 'edgecolor',    [1 1 1]*0.85);
opt.edgewidth           = wxyz_getopt(varargin, 'edgewidth',    0.8);
opt.showedge            = wxyz_getopt(varargin, 'showedge',     true);
opt.nancolor            = wxyz_getopt(varargin, 'nancolor',     [1 1 1]*0.8);
opt.shownan             = wxyz_getopt(varargin, 'shownan',      true);
opt.rowlabel            = wxyz_getopt(varargin, 'rowlabel',     '');
opt.collabel            = wxyz_getopt(varargin, 'collabel',     '');
opt.showlabel           = wxyz_getopt(varargin, 'showlabel',    true);
opt.labelvisible        = wxyz_getopt(varargin, 'labelvisible', 'all'); % all/row/col
opt.showtext            = wxyz_getopt(varargin, 'showtext',     true);
opt.textcolor           = wxyz_getopt(varargin, 'textcolor',    [0 0 0]); % interp or 1*3 matrix
% -- advanced parameter --
opt.textformat          = wxyz_getopt(varargin, 'textformat',   '%.2f');

%% Set obj property. obj.gca -> axis
opt.ax                  = gca;
opt.ax.LineWidth        = 0.8;
opt.ax.YDir             = 'reverse';
opt.ax.TickDir          = 'none';
opt.ax.XLim             = [0.5 size(data, 2)+0.5];
opt.ax.YLim             = [0.5 size(data, 1)+0.5];
opt.ax.XTick            = 1:size(data, 2);
opt.ax.YTick            = 1:size(data, 1);
opt.ax.DataAspectRatio  = [1, 1, 1];
opt.ax.Colormap         = opt.colormap;
opt.maxValue            = max(max(abs(data)));

%% === Start draw ===
%% Draw edge
bX1 = repmat([0.5, size(data,2)+0.5, nan], [size(data,1)+1, 1])';
bY1 = repmat((0.5:1:(size(data,1)+0.5))', [1, 3])';
bX2 = repmat((0.5:1:(size(data,2)+0.5))', [1, 3])';
bY2 = repmat([0.5, size(data,1)+0.5, nan], [size(data, 2)+1, 1])';
opt.boxHdl = plot(opt.ax, [bX1(:); bX2(:)], [bY1(:); bY2(:)], 'LineWidth', opt.edgewidth, 'Color', opt.edgecolor);
if isequal(opt.format, 'square') || ~opt.showedge
    set(opt.boxHdl, 'Color', [1, 1, 1, 0]);
end

%% Draw face
baseT = linspace(0, 2*pi, 200); % for type circular/auto-circular/oval/pie
baseCircX = cos(baseT).*0.92.*0.5;
baseCircY = sin(baseT).*0.92.*0.5;
hexT = linspace(0, 2*pi, 7); % for type hex
thetaMat = [1, -1; 1, 1].*sqrt(2)./2; % for type oval

for row = 1:size(data, 1)
    for col = 1:size(data, 2)
        if isnan(data(row, col))
            if opt.shownan
                opt.patchHdl(row, col)  = fill(opt.ax, [-0.5,0.5,0.5,-0.5].*0.98+col, [-0.5,-0.5,0.5,0.5].*0.98+row, opt.nancolor, 'EdgeColor', 'none');
                opt.pieHdl(row, col)    = fill(opt.ax, [0,0,0,0], [0,0,0,0], [0,0,0]);
            else
                opt.patchHdl(row, col)  = fill(opt.ax, [-0.5,0.5,0.5,-0.5].*0.98+col, [-0.5,-0.5,0.5,0.5].*0.98+row, opt.nancolor, 'EdgeColor', 'none', 'FaceAlpha', 0);
                opt.pieHdl(row, col)    = fill(opt.ax, [0,0,0,0], [0,0,0,0], [0,0,0]);
            end
        else
            tRatio = abs(data(row, col))./opt.maxValue;
            switch opt.format
                case 'square'
                    opt.patchHdl(row, col) = fill(opt.ax, [-0.5,0.5,0.5,-0.5].*0.98+col, [-0.5,-0.5,0.5,0.5].*0.98+row, data(row,col), 'EdgeColor', 'none');
                case 'auto-square'
                    opt.patchHdl(row, col) = fill(opt.ax, [-0.5,0.5,0.5,-0.5].*0.98.*tRatio+col, [-0.5,-0.5,0.5,0.5].*0.98.*tRatio+row, data(row,col), 'EdgeColor', 'none');
                case 'circular'
                    opt.patchHdl(row, col) = fill(opt.ax, baseCircX+col, baseCircY+row, data(row,col), 'EdgeColor', 'none', 'lineWidth', 0.8);
                case 'auto-circular'
                    opt.patchHdl(row, col) = fill(opt.ax, baseCircX.*tRatio+col, baseCircY.*tRatio+row, data(row,col), 'EdgeColor', 'none', 'lineWidth', 0.8);
                case 'oval'
                    tValue = data(row,col)./opt.maxValue;
                    baseA = 1+(tValue<=0).*tValue;
                    baseB = 1-(tValue>=0).*tValue;
                    baseOvalX = cos(baseT).*.98.*.5.*baseA;
                    baseOvalY = sin(baseT).*.98.*.5.*baseB;
                    baseOvalXY=thetaMat*[baseOvalX;baseOvalY];
                    opt.patchHdl(row, col) = fill(opt.ax, baseOvalXY(1,:)+col, -baseOvalXY(2,:)+row, data(row,col), 'EdgeColor', [1,1,1].*0.3, 'lineWidth', 0.8);
                case 'pie'
                    opt.pieHdl(row, col) = fill(opt.ax, baseCircX+col, baseCircY+row, [1,1,1], 'EdgeColor', [1,1,1].*0.3, 'LineWidth', 0.8);
                    baseTheta = linspace(pi/2, pi/2+data(row,col)./opt.maxValue.*2.*pi, 200);
                    basePieX = [0, cos(baseTheta).*.92.*.5];
                    basePieY = [0, sin(baseTheta).*.92.*.5];
                    opt.patchHdl(row, col) = fill(opt.ax, basePieX+col, -basePieY+row, data(row,col), 'EdgeColor', [1,1,1].*0.3, 'lineWidth', 0.8);
                case 'hexagon'
                    opt.patchHdl(row, col) = fill(opt.ax, cos(hexT).*.5.*.98.*tRatio+col, sin(hexT).*.5.*.98.*tRatio+row, data(row,col), 'EdgeColor', [1,1,1].*0.3, 'lineWidth', 0.8);
            end
        end % if isnan value
    end % for col
end % for row

%% Draw text
if opt.showtext
    graymap = mean(get(opt.ax, 'Colormap'), 2);
    climit = get(opt.ax, 'CLim');
    for row = 1:size(data, 1)
        for col = 1:size(data, 2)
            if isnan(data(row, col))
                opt.textHdl(row, col) = text(opt.ax, col, row, '×', 'HorizontalAlignment', 'center');
            else
                opt.textHdl(row, col) = text(opt.ax, col, row, sprintf(opt.textformat, data(row, col)), 'HorizontalAlignment', 'center');
            end
            if ischar(opt.textcolor) && strcmpi(opt.textcolor, 'interp')
                set(opt.textHdl(row, col), 'Color', [1,1,1].*(interp1(linspace(climit(1),climit(2),size(graymap,1)), graymap, data(row,col))<.5));
            else
                set(opt.textHdl(row, col), 'Color', opt.textcolor);
            end
        end
    end
end

%% Draw italic grid label
% TODO

%% Set XTick/XTickLabel and YTick/YTickLabel
opt.XVarName = arrayfun(@(x) strcat('Var-', num2str(x)), 1:size(data, 2), 'UniformOutput', false);
opt.YVarName = arrayfun(@(x) strcat('Var-', num2str(x)), 1:size(data, 1), 'UniformOutput', false);
if opt.showlabel
    if isempty(opt.rowlabel)
        opt.rowlabel = opt.XVarName;
    end
    if isempty(opt.collabel)
        opt.collabel = opt.YVarName;
    end
    if strcmpi(opt.labelvisible, 'all')
        opt.ax.XTickLabel = opt.rowlabel;
        opt.ax.YTickLabel = opt.collabel;
    elseif strcmpi(opt.labelvisible, 'row')
        opt.ax.XTickLabel = opt.rowlabel;
        opt.ax.YTickLabel = [];
    elseif strcmpi(opt.labelvisible, 'col')
        opt.ax.YTickLabel = opt.collabel;
        opt.ax.XTickLabel = [];
    end
else
    opt.ax.XTickLabel = [];
    opt.ax.YTickLabel = [];
end

%% Set type full/triu/tril/triu0/tril0
if size(data,1)==size(data,2)
    opt.ax.XAxisLocation = 'bottom';
    opt.ax.YAxisLocation = 'left';
    bX1 = repmat([0.5, size(data,2)+0.5, nan], [size(data,1)+1, 1])';
    bY1 = repmat((0.5:1:(size(data,1)+0.5))', [1, 3])';
    bX2 = repmat((0.5:1:(size(data,2)+0.5))', [1, 3])';
    bY2 = repmat([0.5, size(data,1)+0.5, nan], [size(data,2)+1, 1])';
    switch opt.type
        case 'full' % full matrix
            % do nothing
        case 'triu' % upper triangle
            opt.ax.XAxisLocation = 'top';
            opt.ax.YAxisLocation = 'right';
            for row = 1:size(data, 1)
                for col = 1:(row-1)
                    set(opt.patchHdl(row, col),'Visible','off');
                    if isfield(opt, 'textHdl')
                        set(opt.textHdl(row, col),'Visible','off');
                    end
                    if isequal(opt.format, 'pie')
                        set(opt.pieHdl(row, col),'Visible','off')
                    end
                end
            end
            bX1(1, 2:end) = bX1(1, 2:end)+(0:size(data, 1)-1);
            bY2(2, :) = [1.5:1:(size(data, 1)+.5), (size(data, 1)+.5)];
            set(opt.boxHdl, 'XData', [bX1(:); bX2(:)], 'YData', [bY1(:); bY2(:)]);
        case 'tril' % lower triangle
            for col = 1:size(data, 2)
                for row = 1:(col-1)
                    set(opt.patchHdl(row, col),'Visible','off');
                    if isfield(opt, 'textHdl')
                        set(opt.textHdl(row, col),'Visible','off');
                    end
                    if isequal(opt.format, 'pie')
                        set(opt.pieHdl(row, col),'Visible','off')
                    end
                end
            end
            bX1(2, 1:end-1) = bX1(2, 1:end-1)-(size(data, 1)-1:-1:0);
            bY2(1, :) = [0.5, 0.5:1:(size(data, 1)-0.5)];
            set(opt.boxHdl, 'XData', [bX1(:); bX2(:)], 'YData', [bY1(:); bY2(:)]);
        case 'triu0' % upper triangle without diagonal
            opt.ax.XAxisLocation = 'top';
            opt.ax.YAxisLocation = 'right';
            for row = 1:size(data, 1)
                for col = 1:row
                    set(opt.patchHdl(row, col),'Visible','off');
                    if isfield(opt, 'textHdl')
                        set(opt.textHdl(row, col),'Visible','off');
                    end
                    if isequal(opt.format, 'pie')
                        set(opt.pieHdl(row, col),'Visible','off')
                    end
                end
            end
            bX1(1, :) = bX1(1, :)+1;
            bX1(1, 2:end) = bX1(1, 2:end)+(0:size(data, 1)-1);
            bY2(2, :) = [1.5:1:(size(data, 1)+0.5), (size(data, 1)+0.5)]-1;
            set(opt.boxHdl, 'XData', [bX1(:); bX2(:)], 'YData', [bY1(:); bY2(:)]);
            opt.ax.XTick = 2:size(data, 1);
            opt.ax.YTick = 1:size(data, 2)-1;
            opt.ax.XTickLabel = opt.rowlabel(2:end);
            opt.ax.YTickLabel = opt.collabel(1:end-1);
        case 'tril0' % lower triangle without diagonal
            for col = 1:size(data, 2)
                for row = 1:col
                    set(opt.patchHdl(row, col),'Visible','off');
                    if isfield(opt, 'textHdl')
                        set(opt.textHdl(row, col),'Visible','off');
                    end
                    if isequal(opt.format, 'pie')
                        set(opt.pieHdl(row, col),'Visible','off')
                    end
                end
            end
            bX1(2, :) = bX1(2, :)-1;
            bX1(2, 1:end-1) = bX1(2, 1:end-1)-(size(data, 1)-1:-1:0);
            bY2(1, :) = [0.5, 0.5:1:(size(data, 1)-0.5)]+1;
            set(opt.boxHdl, 'XData', [bX1(:); bX2(:)], 'YData', [bY1(:); bY2(:)]);
            opt.ax.XTick = 1:size(data, 1)-1;
            opt.ax.YTick = 2:size(data, 2);
            opt.ax.XTickLabel = opt.rowlabel(1:end-1);
            opt.ax.YTickLabel = opt.collabel(2:end);
    end
else
    % only full type can be used.
end

%% Remove axis box edge
pause(0.01); % wait for obj.ax take effect
opt.ax.XRuler.Axle.LineStyle = 'none';
opt.ax.YRuler.Axle.LineStyle = 'none';
%% === End draw ===

% Output
if opt.showedge
    hedge = opt.boxHdl;
else
    hedge = [];
end
hface = opt.patchHdl;
if opt.showtext
    htext = opt.textHdl;
else
    htext = [];
end

%% End
if ~holdflag
  hold off
end