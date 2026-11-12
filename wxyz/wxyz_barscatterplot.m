function [hbar, hlgd] = wxyz_barscatterplot(data, varargin)
%WXYZ_BARSCATTERPLOT Plot grouped means, observations, and error bars.
%
%   WXYZ_BARSCATTERPLOT(DATA) plots the mean of DATA along its second
%   dimension. DATA must be a nonempty real numeric array whose dimensions
%   are interpreted as:
%
%       number of groups x number of samples x number of conditions
%
%   A two-dimensional matrix is therefore interpreted as groups-by-samples
%   with one condition. To plot one group with multiple conditions, retain
%   the singleton first dimension explicitly, for example:
%
%       data = reshape(data, 1, numberOfSamples, numberOfConditions);
%
%   [HBAR, HLGD] = WXYZ_BARSCATTERPLOT(DATA, Name, Value, ...) returns the
%   Bar objects and, when shown, the Legend object. HLGD is empty when
%   'ShowLegend' is false.
%
%   Name-value options (names are case-insensitive):
%       'Legend'           Condition labels. Use a string vector, character
%                          vector, or cell array of character vectors. An
%                          empty value uses MATLAB's default series names.
%       'LegendOri'        'vertical' (default) or 'horizontal'.
%       'ShowLegend'       Logical scalar; default true.
%       'XTick'            Group tick labels. Empty leaves MATLAB's default
%                          numeric group labels in place.
%       'XLabel'           X-axis label; default empty.
%       'YLabel'           Y-axis label; default empty.
%       'Title'            Axes title; default empty.
%       'Show0Err'         Show zero-length error bars; default false.
%       'ErrorType'        'std' (default) or 'sem'. SEM is STD divided by
%                          sqrt(numberOfSamples).
%       'BarWidth'         Bar-group width in (0,1]; default 1.
%       'FaceColor'        One RGB row (reused for all conditions) or one
%                          RGB row per condition; default LINES colors.
%       'FaceAlpha'        Bar-face alpha in [0,1]; default 1.
%       'EdgeColor'        MATLAB color specification or 'none'; default
%                          'none'.
%       'EdgeAlpha'        Bar-edge alpha in [0,1]; default 1.
%       'Marker'           Scatter marker symbol; default 'o'.
%       'MarkerSize'       Scatter marker area; default 60.
%       'MarkerEdgeColor'  MATLAB color specification; default 'k'.
%       'MarkerFaceAlpha'  Scatter-face alpha in [0,1]; default 0.6.
%       'MarkerXJitter'    Random x-jitter width; default 0.15.
%       'ShowMarker'       Logical scalar; default false.
%       'ErrBarOri'        Error-bar orientation. Only 'vertical' is valid
%                          because this function creates vertical bars.
%       'ErrBarStyle'      Error-bar line style; default 'none'.
%       'ErrBarWidth'      Error-bar line width; default 2.
%       'ErrBarColor'      MATLAB color specification; default 'k'.
%       'ErrBarCapSize'    Error-bar cap size; default 6.
%       'Parent'           Target axes. Default is the current axes.
%
%   Important usage notes:
%   * This function depends on WXYZ_GETOPT from the WXYZ library. Option
%     names must be character vectors, as required by that helper. Unknown
%     options are ignored, matching the behavior of the original function.
%   * NaN and Inf values are not removed. They propagate through MEAN/STD;
%     remove or replace missing/nonfinite observations before calling.
%   * STD and SEM describe variability across dimension 2. With one sample,
%     the computed error is zero.
%   * Random scatter jitter changes marker positions on each call. Set the
%     random-number seed before calling when reproducibility is required.
%   * Existing axes hold state is restored, but axis labels, title, ticks,
%     and legend may be updated by this function.
%
%   Example:
%       data = randn(3, 20, 2) + reshape([0 0.5], 1, 1, []);
%       wxyz_barscatterplot(data, 'ShowMarker', true, ...
%           'Legend', ["control" "treatment"], ...
%           'XTick', ["G1" "G2" "G3"], 'ErrorType', 'sem');
%
%   @author: wxyz. 2024/11/28. Revised 2026/08/01.

    validateattributes(data, {'numeric'}, {'real', 'nonempty'}, mfilename, 'data', 1);
    if ndims(data) > 3
        error('wxyz_barscatterplot:InvalidDataDimensions', 'DATA must have at most three dimensions: group-by-sample-by-condition.');
    end

    nGroup = size(data, 1);
    nSamp = size(data, 2);
    nCond = size(data, 3);

    isFiniteNumericScalar = @(x) isnumeric(x) && isscalar(x) && isreal(x) && isfinite(x);
    isLogicalScalar = @(x) (islogical(x) || isnumeric(x)) && isscalar(x) && isreal(x) && isfinite(x) && (x == 0 || x == 1);
    isText = @(x) ischar(x) || isstring(x);
    isTextScalar = @(x) ischar(x) || (isstring(x) && isscalar(x));
    isTextOrCell = @(x) isText(x) || iscellstr(x); %#ok<ISCLSTR>
    isNonnegativeScalar = @(x) isFiniteNumericScalar(x) && x >= 0;
    isPositiveScalar = @(x) isFiniteNumericScalar(x) && x > 0;
    isUnitScalar = @(x) isFiniteNumericScalar(x) && x >= 0 && x <= 1;
    isRgbColor = @(x) isnumeric(x) && isreal(x) && isequal(size(x), [1 3]) && all(isfinite(x), 'all') && all(x >= 0 & x <= 1, 'all');
    isColor = @(x) isRgbColor(x) || isTextScalar(x);

    % Read options with the helper used throughout the WXYZ library.
    opt.Legend = wxyz_getopt(varargin, 'legend', []);
    opt.LegendOri = wxyz_getopt(varargin, 'legendori', 'vertical');
    opt.ShowLegend = wxyz_getopt(varargin, 'showlegend', true);
    opt.XTick = wxyz_getopt(varargin, 'xtick', []);
    opt.XLabel = wxyz_getopt(varargin, 'xlabel', '');
    opt.YLabel = wxyz_getopt(varargin, 'ylabel', '');
    opt.Title = wxyz_getopt(varargin, 'title', '');
    opt.Show0Err = wxyz_getopt(varargin, 'show0err', false);
    opt.ErrorType = wxyz_getopt(varargin, 'errortype', 'std');
    opt.BarWidth = wxyz_getopt(varargin, 'BarWidth', 1);
    opt.FaceColor = wxyz_getopt(varargin, 'facecolor', lines(nCond));
    opt.FaceAlpha = wxyz_getopt(varargin, 'facealpha', 1);
    opt.EdgeColor = wxyz_getopt(varargin, 'edgecolor', 'none');
    opt.EdgeAlpha = wxyz_getopt(varargin, 'edgealpha', 1);
    opt.Marker = wxyz_getopt(varargin, 'marker', 'o');
    opt.MarkerSize = wxyz_getopt(varargin, 'markerSize', 60);
    opt.MarkerEdgeColor = wxyz_getopt(varargin, 'markerEdgeColor', 'k');
    opt.MarkerFaceAlpha = wxyz_getopt(varargin, 'markerFaceAlpha', 0.6);
    opt.MarkerXJitter = wxyz_getopt(varargin, 'markerXJitter', 0.15);
    opt.ShowMarker = wxyz_getopt(varargin, 'showmarker', false);
    opt.ErrBarOri = wxyz_getopt(varargin, 'errBarOri', 'vertical');
    opt.ErrBarStyle = wxyz_getopt(varargin, 'errBarStyle', 'none');
    opt.ErrBarWidth = wxyz_getopt(varargin, 'errBarWidth', 2);
    opt.ErrBarColor = wxyz_getopt(varargin, 'errBarColor', 'k');
    opt.ErrBarCapSize = wxyz_getopt(varargin, 'errBarCapSize', 6);
    opt.Parent = wxyz_getopt(varargin, 'parent', []);

    invalidLegend = ~isempty(opt.Legend) && ~isTextOrCell(opt.Legend);
    invalidXTick = ~isempty(opt.XTick) && ~isTextOrCell(opt.XTick);
    invalidAxisText = ~isText(opt.XLabel) || ~isText(opt.YLabel) || ~isText(opt.Title);
    if invalidLegend || invalidXTick || invalidAxisText
        error('wxyz_barscatterplot:InvalidTextOption', 'Legend, XTick, XLabel, YLabel, and Title must contain text values.');
    end

    invalidLogicalOption = ~isLogicalScalar(opt.ShowLegend) || ~isLogicalScalar(opt.Show0Err) || ~isLogicalScalar(opt.ShowMarker);
    if invalidLogicalOption
        error('wxyz_barscatterplot:InvalidLogicalOption', 'ShowLegend, Show0Err, and ShowMarker must be logical scalars or numeric 0/1.');
    end

    invalidBarWidth = ~isPositiveScalar(opt.BarWidth) || opt.BarWidth > 1;
    invalidAlpha = ~isUnitScalar(opt.FaceAlpha) || ~isUnitScalar(opt.EdgeAlpha) || ~isUnitScalar(opt.MarkerFaceAlpha);
    invalidMarkerSize = ~isNonnegativeScalar(opt.MarkerSize) || ~isNonnegativeScalar(opt.MarkerXJitter);
    invalidErrorBarSize = ~isPositiveScalar(opt.ErrBarWidth) || ~isNonnegativeScalar(opt.ErrBarCapSize);
    if invalidBarWidth || invalidAlpha || invalidMarkerSize || invalidErrorBarSize
        error('wxyz_barscatterplot:InvalidNumericOption', 'One or more size, width, or alpha options are outside their valid range.');
    end

    invalidColor = ~isColor(opt.EdgeColor) || ~isColor(opt.MarkerEdgeColor) || ~isColor(opt.ErrBarColor);
    invalidMarkerOrLine = ~isTextScalar(opt.Marker) || ~isTextScalar(opt.ErrBarStyle);
    if invalidColor || invalidMarkerOrLine
        error('wxyz_barscatterplot:InvalidGraphicsOption', 'One or more color, marker, or line-style options are invalid.');
    end

    if ~isempty(opt.Parent) && ~isgraphics(opt.Parent, 'axes')
        error('wxyz_barscatterplot:InvalidParent', 'Parent must be a valid axes handle.');
    end

    errType = validatestring(opt.ErrorType, {'std', 'sem'}, mfilename, 'ErrorType');
    legendOrientation = validatestring(opt.LegendOri, {'vertical', 'horizontal'}, mfilename, 'LegendOri');
    validatestring(opt.ErrBarOri, {'vertical'}, mfilename, 'ErrBarOri');

    faceColor = opt.FaceColor;
    if isequal(size(faceColor), [1 3])
        faceColor = repmat(faceColor, nCond, 1);
    end
    invalidFaceColorSize = ~isequal(size(faceColor), [nCond 3]);
    invalidFaceColorValue = any(~isfinite(faceColor), 'all') || any(faceColor < 0 | faceColor > 1, 'all');
    if invalidFaceColorSize || invalidFaceColorValue
        error('wxyz_barscatterplot:InvalidFaceColor', 'FaceColor must be a 1-by-3 RGB row or an nCondition-by-3 RGB matrix in [0,1].');
    end

    if ischar(opt.XTick)
        nXTickLabels = size(opt.XTick, 1);
    else
        nXTickLabels = numel(opt.XTick);
    end
    if ~isempty(opt.XTick) && nXTickLabels ~= nGroup
        error('wxyz_barscatterplot:InvalidXTickCount', 'XTick must contain exactly one label for each of the %d groups.', nGroup);
    end

    if ischar(opt.Legend)
        nLegendLabels = size(opt.Legend, 1);
    else
        nLegendLabels = numel(opt.Legend);
    end
    if ~isempty(opt.Legend) && nLegendLabels ~= nCond
        error('wxyz_barscatterplot:InvalidLegendCount', 'Legend must contain exactly one label for each of the %d conditions.', nCond);
    end

    if isempty(opt.Parent)
        ax = gca;
    else
        ax = opt.Parent;
    end

    holdWasOn = ishold(ax);
    if ~holdWasOn
        hold(ax, 'on');
        holdCleanup = onCleanup(@() hold(ax, 'off'));
    end

    % RESHAPE preserves singleton group and condition dimensions (unlike SQUEEZE).
    meanData = reshape(mean(data, 2), nGroup, nCond);
    hbar = bar(ax, (1:nGroup).', meanData, 'FaceAlpha', opt.FaceAlpha, 'EdgeColor', opt.EdgeColor, 'EdgeAlpha', opt.EdgeAlpha, 'BarWidth', opt.BarWidth);

    for iCond = 1:nCond
        set(hbar(iCond), 'FaceColor', faceColor(iCond, :));
        sampleData = reshape(data(:, :, iCond), nGroup, nSamp);
        meanForCondition = meanData(:, iCond);
        xPosition = hbar(iCond).XEndPoints(:);

        switch errType
            case 'std'
                errorSize = std(sampleData, 0, 2);
            case 'sem'
                errorSize = std(sampleData, 0, 2) / sqrt(nSamp);
        end

        if logical(opt.ShowMarker)
            scatterX = repmat(xPosition, 1, nSamp);
            scatter(ax, scatterX(:), sampleData(:), opt.MarkerSize, 'filled', opt.Marker, 'MarkerEdgeColor', opt.MarkerEdgeColor, 'CData', faceColor(iCond, :), 'XJitter', 'rand', 'XJitterWidth', opt.MarkerXJitter, 'MarkerFaceAlpha', opt.MarkerFaceAlpha, 'HandleVisibility', 'off');
        end

        if logical(opt.Show0Err)
            showError = true(nGroup, 1);
        else
            showError = errorSize ~= 0;
        end
        errorbar(ax, xPosition(showError), meanForCondition(showError), errorSize(showError), 'vertical', 'LineStyle', opt.ErrBarStyle, 'LineWidth', opt.ErrBarWidth, 'Color', opt.ErrBarColor, 'CapSize', opt.ErrBarCapSize, 'HandleVisibility', 'off');
    end

    xticks(ax, 1:nGroup);
    if ~isempty(opt.XTick)
        xticklabels(ax, opt.XTick);
    end
    set(ax, 'TickLabelInterpreter', 'none');
    xlabel(ax, opt.XLabel);
    ylabel(ax, opt.YLabel);
    title(ax, opt.Title);

    if logical(opt.ShowLegend)
        if isempty(opt.Legend)
            hlgd = legend(ax, hbar);
        else
            hlgd = legend(ax, hbar, opt.Legend);
        end
        hlgd.AutoUpdate = 'off';
        hlgd.Orientation = legendOrientation;
    else
        hlgd = [];
    end

    if nargout == 0
        clear hbar hlgd
    end
end
