function wxyz_setCMapCutOff(varargin)
% wxyz_setCMapCutOff
% ======================================================
% usage:
%   wxyz_setCMapCutOff([-1 1]);
%   wxyz_setCMapCutOff([-1 1], [0 0 0]);
%   wxyz_setCMapCutOff(ax, [-1 1]);
%   wxyz_setCMapCutOff(ax, [-1 1], [0 0 0]);
% ======================================================
% @author:  wxyz. 2024/10/12

ax = [];
cutoff = [];
fixColor = [];

if nargin == 0
    warning('The number of input variables is empty, please check');
    return;
else
    if nargin == 1
        ax = gca;
        cutoff = varargin{1};
    elseif nargin == 2
        if isa(varargin{1},'matlab.graphics.axis.Axes')
            ax = varargin{1};
            cutoff = varargin{2};
        else
            ax = gca;
            cutoff = varargin{1};
            fixColor = varargin{2};
        end
    elseif nargin == 3
        ax = varargin{1};
        cutoff = varargin{2};
        fixColor = varargin{3};
    end
end

if isnumeric(cutoff) && length(cutoff) ~= 2
    warning('The cutoff value is wrong, please check');
    return;
end

if ~isempty(fixColor) && isnumeric(fixColor) && size(fixColor, 1) ~= 1
    warning('The fixColor number should be 1, please check');
    return;
end

% Get current data limits
CLimit = get(ax,'CLim');
% Get current colormap
CMap = get(ax, 'ColorMap');
nColors = size(CMap, 1);
% Calculates the colormap index corresponding to the range of input
minIdx = round((cutoff(1) - CLimit(1)) / (CLimit(2) - CLimit(1)) * (nColors - 1)) + 1;
maxIdx = round((cutoff(2) - CLimit(1)) / (CLimit(2) - CLimit(1)) * (nColors - 1)) + 1;
% Make sure the index is in a valid range
minIdx = max(1, min(minIdx, nColors));
maxIdx = max(1, min(maxIdx, nColors));

% Generate new colormap
newCMap = CMap;

if minIdx == 1 || maxIdx == nColors
    if minIdx == 1
        newBreak = 1;
        old_indices = linspace(1, nColors-newBreak, nColors-newBreak);
        new_length  = nColors - maxIdx;
        new_indices = linspace(1, nColors-newBreak, new_length);
        newCMap(maxIdx+1:end, :) = interp1(old_indices, CMap(newBreak+1:end, :), new_indices);
        if isempty(fixColor)
            fixColor = CMap(newBreak, :);
        end
        newCMap(minIdx:maxIdx, :) = repmat(fixColor, maxIdx - minIdx + 1, 1);
    end
    if maxIdx == nColors
        newBreak = maxIdx;
        old_indices = linspace(1, newBreak, newBreak);
        new_length  = minIdx;
        new_indices = linspace(1, newBreak, new_length);
        newCMap(1:minIdx, :) = interp1(old_indices, CMap(1:newBreak, :), new_indices);
        if isempty(fixColor)
            fixColor = CMap(newBreak, :);
        end
        newCMap(minIdx:maxIdx, :) = repmat(fixColor, maxIdx - minIdx + 1, 1);
    end
else
    newBreak = round((minIdx + maxIdx)/2);
    % Set default fix color
    if isempty(fixColor)
        fixColor = CMap(newBreak, :);
    end
    newCMap(minIdx:maxIdx, :) = repmat(fixColor, maxIdx - minIdx + 1, 1);
    old_indices = linspace(1, newBreak, newBreak);
    new_length  = minIdx;
    new_indices = linspace(1, newBreak, new_length);
    newCMap(1:minIdx, :) = interp1(old_indices, CMap(1:newBreak, :), new_indices);

    old_indices = linspace(1, nColors-newBreak, nColors-newBreak);
    new_length  = nColors - maxIdx;
    new_indices = linspace(1, nColors-newBreak, new_length);
    newCMap(maxIdx+1:end, :) = interp1(old_indices, CMap(newBreak+1:end, :), new_indices);
end

% Apply new colormap
colormap(newCMap);
