function h = wxyz_stackedbar(segmentHeights, colors, varargin)
    % WXYZ_STACKEDBAR Plot stacked bars in the current axes.
    %
    %   H = WXYZ_STACKEDBAR(segmentHeights, COLORS)
    %   H = WXYZ_STACKEDBAR(segmentHeights, COLORS, Name, Value, ...)
    %
    %   segmentHeights - Finite, nonnegative matrix of segment heights.
    %                    Rows are bars, and columns are categories.
    %   colors         - One RGB row in [0,1] per category.
    %
    %   Name-value options (case insensitive):
    %       'Connected'      Connect adjacent bars with ribbons. Default true.
    %       'ShowValues'     Label each positive-height segment with its value.
    %                        Default true.
    %       'BarWidth'       Bar width in (0,1). Default 0.6.
    %       'EdgeWidth'      Bar edge line width in points. Default 0.5.
    %       'EdgeColor'      MATLAB color or 'none'. Default [0 0 0] (black).
    %       'ColorWeight'    Ribbon color blend in [0,1], from white to the
    %                        category color. Default 0.45.
    %       'SeparatorWidth' White ribbon separator width in points. Default 1.5.
    %   Connected and ShowValues accept logical scalars or numeric 0/1.
    %
    %   h - One Bar object per category. Pass these handles to LEGEND.
    %
    %   Example:
    %       figure;
    %       segmentHeights = [3 2; 1 4; 2 0];
    %       h = wxyz_stackedbar(segmentHeights, lines(2), 'EdgeWidth', 1, 'EdgeColor', 'k');
    %       legend(h, {'A', 'B'});
    %
    %   See also bar, patch, legend

    if ~isnumeric(segmentHeights) || ~ismatrix(segmentHeights) || isempty(segmentHeights) || ~isreal(segmentHeights) || any(~isfinite(segmentHeights(:)) | segmentHeights(:) < 0)
        error('wxyz_stackedbar:InvalidSegmentHeights', 'segmentHeights must be a nonempty numeric matrix of finite, nonnegative heights.');
    end
    [nBars, nCategories] = size(segmentHeights);
    if ~isnumeric(colors) || ~isreal(colors) || ~isequal(size(colors), [nCategories 3]) || any(~isfinite(colors(:)) | colors(:) < 0 | colors(:) > 1)
        error('wxyz_stackedbar:InvalidColors', 'colors must contain one RGB row in [0,1] per category.');
    end

    % Read name-value options using the WXYZ library convention.
    opt.Connected = wxyz_getopt(varargin, 'Connected', true);
    opt.ShowValues = wxyz_getopt(varargin, 'ShowValues', true);
    opt.BarWidth = wxyz_getopt(varargin, 'BarWidth', 0.6);
    opt.EdgeWidth = wxyz_getopt(varargin, 'EdgeWidth', 0.5);
    opt.EdgeColor = wxyz_getopt(varargin, 'EdgeColor', [0 0 0]);
    opt.ColorWeight = wxyz_getopt(varargin, 'ColorWeight', 0.45);
    opt.SeparatorWidth = wxyz_getopt(varargin, 'SeparatorWidth', 1.5);

    isToggle = @(value) (islogical(value) || isnumeric(value)) && isscalar(value) && isreal(value) && (value == 0 || value == 1);
    if ~isToggle(opt.Connected) || ~isToggle(opt.ShowValues)
        error('wxyz_stackedbar:InvalidToggle', 'Connected and ShowValues must be logical scalars or numeric 0/1.');
    end
    if ~isnumeric(opt.BarWidth) || ~isscalar(opt.BarWidth) || ~isreal(opt.BarWidth) || ~(opt.BarWidth > 0 && opt.BarWidth < 1)
        error('wxyz_stackedbar:InvalidBarWidth', 'BarWidth must be a scalar in (0,1).');
    end
    if ~isnumeric(opt.ColorWeight) || ~isscalar(opt.ColorWeight) || ~isreal(opt.ColorWeight) || ~(opt.ColorWeight >= 0 && opt.ColorWeight <= 1)
        error('wxyz_stackedbar:InvalidColorWeight', 'ColorWeight must be a scalar in [0,1].');
    end

    segmentHeights = full(double(segmentHeights));
    colors = full(double(colors));
    opt.BarWidth = double(opt.BarWidth);
    opt.ColorWeight = double(opt.ColorWeight);
    opt.SeparatorWidth = double(opt.SeparatorWidth);

    ax = gca;
    previousNextPlot = ax.NextPlot;
    restoreAxes = onCleanup(@() set(ax, 'NextPlot', previousNextPlot));
    hold(ax, 'on');

    % Draw ribbons first so that the bar edges remain visible.
    if opt.Connected && nBars > 1
        plotRibbons(ax, segmentHeights, colors, opt);
    end

    x = 1:nBars;
    barHeights = segmentHeights;
    if nBars == 1 && nCategories > 1
        % An invisible second bar keeps the columns as separate categories.
        x = [1 2];
        barHeights = [segmentHeights; nan(1, nCategories)];
        xlim(ax, [0.5 1.5]);
    end

    h = bar(ax, x, barHeights, 'stacked', 'BarWidth', opt.BarWidth, 'EdgeColor', opt.EdgeColor, 'LineWidth', opt.EdgeWidth);
    for category = 1:nCategories
        h(category).FaceColor = colors(category, :);
    end
    if opt.ShowValues
        labelSegments(ax, segmentHeights, colors);
    end
end

function plotRibbons(ax, segmentHeights, colors, opt)
    t = linspace(0, 1, 81);
    ease = t.^2 .* (3 - 2*t);  % Meet the bar edges with zero slope.
    ribbonColors = 1 - opt.ColorWeight * (1 - colors);

    for leftBar = 1:size(segmentHeights, 1)-1
        pair = segmentHeights(leftBar:leftBar+1, :);
        active = find(any(pair > 0, 1));
        if isempty(active)
            continue
        end

        % Each row of yGap traces one cumulative boundary across the gap.
        edges = [zeros(2, 1), cumsum(pair(:, active), 2)].';
        xGap = leftBar + opt.BarWidth/2 + (1 - opt.BarWidth)*t;
        yGap = edges(:, 1).*(1 - ease) + edges(:, 2).*ease;
        xRibbon = [xGap, fliplr(xGap)];

        for k = 1:numel(active)
            yRibbon = [yGap(k, :), fliplr(yGap(k+1, :))];
            patch(ax, xRibbon, yRibbon, ribbonColors(active(k), :), 'EdgeColor', 'none', 'HandleVisibility', 'off');
        end
        for k = 2:numel(active)
            plot(ax, xGap, yGap(k, :), 'w-', 'LineWidth', opt.SeparatorWidth, 'HandleVisibility', 'off');
        end
    end
end

function labelSegments(ax, segmentHeights, colors)
    centers = cumsum(segmentHeights, 2) - segmentHeights/2;
    for category = 1:size(segmentHeights, 2)
        barIndices = find(segmentHeights(:, category) > 0);
        if isempty(barIndices)
            continue
        end

        % Use white text on dark segments and black text on light segments.
        textColor = 'k';
        if colors(category, :) * [0.299; 0.587; 0.114] < 0.5
            textColor = 'w';
        end
        for barIndex = barIndices.'
            label = sprintf('%g', segmentHeights(barIndex, category));
            text(ax, barIndex, centers(barIndex, category), label, 'Color', textColor, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Clipping', 'on', 'HandleVisibility', 'off');
        end
    end
end
