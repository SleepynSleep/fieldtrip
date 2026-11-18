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
%   cmap = wxyz_colormap('draw', type);
%                                      draw colormaps of the specified type.
%   idx = wxyz_colormap('add', name, cmap);
%                                      add an N-by-3 custom colormap;
%                                      floating-point cmap uses [0, 1],
%                                      uint8 cmap uses [0, 255].
%   idx = wxyz_colormap('replace', name, cmap);
%                                      replace a custom colormap.
%   idx = wxyz_colormap('remove', name);
%                                      remove a custom colormap.
%   idx = wxyz_colormap('rename', oldName, newName);
%                                      rename a custom colormap.
% ================================================================
% @author: wxyz. 2024/09/29.
persistent wxyz_cmapdata cmapdata
dataFile = fullfile(fileparts(mfilename('fullpath')), 'wxyz_cmapdata.mat');
picFolder = fullfile(fileparts(mfilename('fullpath')), 'colormap');
if isempty(wxyz_cmapdata)
    loadedData = load(dataFile, 'wxyz_cmapdata');
    wxyz_cmapdata = loadedData.wxyz_cmapdata;
    cmapdata = [wxyz_cmapdata.colormap(:).Colors];
end

if nargin >= 1 && isTextScalar(varargin{1})
    action = lower(string(varargin{1}));

    if action == "draw"
        if nargin > 2
            error('wxyz_colormap:DrawSyntax', 'Use wxyz_colormap(''draw'') or wxyz_colormap(''draw'', type).');
        end
        if nargin == 1
            requestedType = "";
        else
            requestedType = normalizeDrawType(varargin{2});
        end
        drawnColormaps = drawColorMapTypes(wxyz_cmapdata, requestedType, picFolder);
        if nargout > 0
            varargout{1} = drawnColormaps;
        end
        return;
    end

    if any(action == ["add", "remove", "replace", "rename"])
        switch action
            case "add"
                if nargin ~= 3
                    message = 'Use wxyz_colormap(''add'', name, cmap); cmap must be N-by-3 float [0,1] or uint8.';
                    error('wxyz_colormap:AddSyntax', message);
                end
                name = varargin{2};
                [wxyz_cmapdata, cmapdata, affectedIndex] = addCustomMap(wxyz_cmapdata, name, varargin{3}, dataFile);
                fprintf('[wxyz_colormap] Added "%s" (index %d).\n', strtrim(char(string(name))), affectedIndex);

            case "remove"
                if nargin ~= 2
                    error('wxyz_colormap:RemoveSyntax', 'Use wxyz_colormap(''remove'', name).');
                end
                name = varargin{2};
                [wxyz_cmapdata, cmapdata, affectedIndex] = removeCustomMap(wxyz_cmapdata, name, dataFile);
                fprintf('[wxyz_colormap] Removed "%s" (old index %d).\n', strtrim(char(string(name))), affectedIndex);

            case "replace"
                if nargin ~= 3
                    message = 'Use wxyz_colormap(''replace'', name, cmap); cmap must be N-by-3 float [0,1] or uint8.';
                    error('wxyz_colormap:ReplaceSyntax', message);
                end
                name = varargin{2};
                [wxyz_cmapdata, cmapdata, affectedIndex] = replaceCustomMap(wxyz_cmapdata, name, varargin{3}, dataFile);
                fprintf('[wxyz_colormap] Replaced "%s" (index %d).\n', strtrim(char(string(name))), affectedIndex);

            case "rename"
                if nargin ~= 3
                    error('wxyz_colormap:RenameSyntax', 'Use wxyz_colormap(''rename'', oldName, newName).');
                end
                oldName = varargin{2};
                newName = varargin{3};
                [wxyz_cmapdata, cmapdata, affectedIndex] = renameCustomMap(wxyz_cmapdata, oldName, newName, dataFile);
                oldNameText = strtrim(char(string(oldName)));
                newNameText = strtrim(char(string(newName)));
                fprintf('[wxyz_colormap] Renamed "%s" to "%s" (index %d).\n', oldNameText, newNameText, affectedIndex);
        end
        if nargout > 0
            varargout{1} = affectedIndex;
        end
        return;
    end
end

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
        varargout{1} = cellfun(@(cmap) double(cmap)./255, cmapdata, 'UniformOutput', false);
        return;
    else
        cpos = strcmpi(ctype, wxyz_cmapdata.fullNames);
        cmap = cmapdata{cpos};
    end
end
cmap = double(cmap)./255;
nSource = size(cmap, 1);
if cnum ~= nSource
    ci = linspace(0, 1, nSource);
    cq = linspace(0, 1, cnum);
    cmap = interp1(ci, cmap, cq, 'linear');
end
varargout{1} = cmap;
end

%% SUBFUNCTION
function [wxyz_cmapdata, cmapdata, newIndex] = addCustomMap(wxyz_cmapdata, name, cmap, dataFile)
    name = normalizeCustomName(name);
    if isReservedColormapName(name)
        error('wxyz_colormap:ReservedName', 'The name "%s" is reserved by wxyz_colormap.', name);
    end
    if any(strcmpi(name, wxyz_cmapdata.fullNames))
        error('wxyz_colormap:DuplicateName', 'A colormap named "%s" already exists.', name);
    end
    storedCmap = encodeCustomColormap(cmap);

    groupTypes = {wxyz_cmapdata.colormap.Type};
    customGroupIndex = find(strcmpi(groupTypes, 'custom'), 1);
    if isempty(customGroupIndex)
        customGroup = wxyz_cmapdata.colormap(1);
        customGroup.Type = 'custom';
        customGroup.Names = {name};
        customGroup.Colors = {storedCmap};
        wxyz_cmapdata.colormap(end+1) = customGroup;
    else
        customGroup = wxyz_cmapdata.colormap(customGroupIndex);
        wxyz_cmapdata.colormap(customGroupIndex) = [];
        customGroup.Names{end+1} = name;
        customGroup.Colors{end+1} = storedCmap;
        wxyz_cmapdata.colormap(end+1) = customGroup;
    end

    [wxyz_cmapdata, cmapdata] = rebuildColormapIndex(wxyz_cmapdata);
    newIndex = find(strcmpi(name, wxyz_cmapdata.fullNames), 1);
    saveColormapData(wxyz_cmapdata, dataFile);
end

function [wxyz_cmapdata, cmapdata, removedIndex] = removeCustomMap(wxyz_cmapdata, name, dataFile)
    name = normalizeCustomName(name);
    [customGroupIndex, customMapIndex, removedIndex] = findCustomColormap(wxyz_cmapdata, name);

    wxyz_cmapdata.colormap(customGroupIndex).Names(customMapIndex) = [];
    wxyz_cmapdata.colormap(customGroupIndex).Colors(customMapIndex) = [];
    if isempty(wxyz_cmapdata.colormap(customGroupIndex).Names)
        wxyz_cmapdata.colormap(customGroupIndex) = [];
    end

    [wxyz_cmapdata, cmapdata] = rebuildColormapIndex(wxyz_cmapdata);
    saveColormapData(wxyz_cmapdata, dataFile);
end

function [wxyz_cmapdata, cmapdata, replacedIndex] = replaceCustomMap(wxyz_cmapdata, name, cmap, dataFile)
    name = normalizeCustomName(name);
    [customGroupIndex, customMapIndex, replacedIndex] = findCustomColormap(wxyz_cmapdata, name);
    storedCmap = encodeCustomColormap(cmap);

    wxyz_cmapdata.colormap(customGroupIndex).Colors{customMapIndex} = storedCmap;
    [wxyz_cmapdata, cmapdata] = rebuildColormapIndex(wxyz_cmapdata);
    saveColormapData(wxyz_cmapdata, dataFile);
end

function [wxyz_cmapdata, cmapdata, renamedIndex] = renameCustomMap(wxyz_cmapdata, oldName, newName, dataFile)
    oldName = normalizeCustomName(oldName);
    newName = normalizeCustomName(newName);
    [customGroupIndex, customMapIndex, renamedIndex] = findCustomColormap(wxyz_cmapdata, oldName);

    if isReservedColormapName(newName)
        error('wxyz_colormap:ReservedName', 'The name "%s" is reserved by wxyz_colormap.', newName);
    end
    duplicateIndex = find(strcmpi(newName, wxyz_cmapdata.fullNames));
    if any(duplicateIndex ~= renamedIndex)
        error('wxyz_colormap:DuplicateName', 'A colormap named "%s" already exists.', newName);
    end

    wxyz_cmapdata.colormap(customGroupIndex).Names{customMapIndex} = newName;
    [wxyz_cmapdata, cmapdata] = rebuildColormapIndex(wxyz_cmapdata);
    saveColormapData(wxyz_cmapdata, dataFile);
end

function name = normalizeCustomName(name)
    if ~isTextScalar(name)
        error('wxyz_colormap:InvalidName', 'The colormap name must be a nonempty text scalar.');
    end
    nameString = string(name);
    if ismissing(nameString)
        error('wxyz_colormap:InvalidName', 'The colormap name must not be missing.');
    end
    name = strtrim(char(nameString));
    if isempty(name)
        error('wxyz_colormap:InvalidName', 'The colormap name must not be empty.');
    end
end

function tf = isReservedColormapName(name)
    tf = any(strcmpi(name, {'add', 'remove', 'replace', 'rename', 'all', 'draw'}));
end

function storedCmap = encodeCustomColormap(cmap)
    if ~isnumeric(cmap) || ~isreal(cmap) || ~ismatrix(cmap) || ...
            size(cmap, 2) ~= 3 || size(cmap, 1) < 2 || ...
            any(~isfinite(cmap), 'all')
        error('wxyz_colormap:InvalidColormap', 'cmap must be a finite, real numeric N-by-3 array with N >= 2.');
    end

    if isa(cmap, 'uint8')
        storedCmap = cmap;
    elseif isfloat(cmap) && all(cmap >= 0 & cmap <= 1, 'all')
        storedCmap = uint8(round(double(cmap).*255));
    else
        message = 'Floating-point cmap values must be in [0,1]. For [0,255] data, pass a uint8 array.';
        error('wxyz_colormap:InvalidColormapRange', message);
    end
end

function [customGroupIndex, customMapIndex, globalIndex] = findCustomColormap(wxyz_cmapdata, name)
    groupTypes = {wxyz_cmapdata.colormap.Type};
    customGroupIndex = find(strcmpi(groupTypes, 'custom'), 1);
    if isempty(customGroupIndex)
        rejectNoncustomOrMissingName(wxyz_cmapdata, name);
    end

    customMapIndex = find(strcmpi(name, wxyz_cmapdata.colormap(customGroupIndex).Names), 1);
    if isempty(customMapIndex)
        rejectNoncustomOrMissingName(wxyz_cmapdata, name);
    end
    globalIndex = find(strcmpi(name, wxyz_cmapdata.fullNames), 1);
end

function rejectNoncustomOrMissingName(wxyz_cmapdata, name)
    if any(strcmpi(name, wxyz_cmapdata.fullNames))
        message = 'The colormap "%s" is built in; only custom colormaps can be removed, replaced, or renamed.';
        error('wxyz_colormap:ProtectedColormap', message, name);
    end
    error('wxyz_colormap:CustomNameNotFound', 'No custom colormap named "%s" exists.', name);
end

function [wxyz_cmapdata, cmapdata] = rebuildColormapIndex(wxyz_cmapdata)
    wxyz_cmapdata.fullNames = [wxyz_cmapdata.colormap(:).Names];
    cmapdata = [wxyz_cmapdata.colormap(:).Colors];
end

function saveColormapData(wxyz_cmapdata, dataFile)
    dataFolder = fileparts(dataFile);
    temporaryFile = [tempname(dataFolder), '.mat'];
    try
        save(temporaryFile, 'wxyz_cmapdata', '-v7');
        [moveSucceeded, moveMessage] = movefile(temporaryFile, dataFile, 'f');
        if ~moveSucceeded
            error('wxyz_colormap:SaveFailed', '%s', moveMessage);
        end
    catch exception
        if isfile(temporaryFile)
            delete(temporaryFile);
        end
        rethrow(exception);
    end
end

function tf = isTextScalar(value)
    tf = (ischar(value) && (isrow(value) || isempty(value))) || (isstring(value) && isscalar(value));
end

function requestedType = normalizeDrawType(value)
    if ~isTextScalar(value)
        error('wxyz_colormap:InvalidDrawType', 'The draw type must be a nonempty text scalar.');
    end
    requestedType = strtrim(string(value));
    if ismissing(requestedType) || strlength(requestedType) == 0
        error('wxyz_colormap:InvalidDrawType', 'The draw type must be a nonempty text scalar.');
    end
end

function drawnColormaps = drawColorMapTypes(wxyz_cmapdata, requestedType, picFolder)
    groupTypes = string({wxyz_cmapdata.colormap.Type});
    if strlength(requestedType) == 0
        selectedGroupIndices = 1:numel(groupTypes);
    else
        selectedGroupIndices = find(strcmpi(requestedType, groupTypes));
        if isempty(selectedGroupIndices)
            availableTypes = strjoin(groupTypes, ", ");
            message = 'Unknown colormap type "%s". Available types: %s.';
            error('wxyz_colormap:DrawTypeNotFound', message, requestedType, availableTypes);
        end
    end

    selectedGroups = wxyz_cmapdata.colormap(selectedGroupIndices);
    storedColormaps = [selectedGroups(:).Colors];
    drawnColormaps = cellfun(@(cmap) double(cmap)./255, storedColormaps, 'UniformOutput', false);

    if ~isfolder(picFolder)
        mkdir(picFolder);
    end

    pageSize = 100;
    for groupIndex = selectedGroupIndices
        group = wxyz_cmapdata.colormap(groupIndex);
        mapCount = numel(group.Names);
        pageCount = ceil(mapCount/pageSize);
        for pageIndex = 1:pageCount
            firstMap = (pageIndex - 1)*pageSize + 1;
            lastMap = min(pageIndex*pageSize, mapCount);
            pageGroup = group;
            pageGroup.Names = group.Names(firstMap:lastMap);
            pageGroup.Colors = group.Colors(firstMap:lastMap);

            if pageCount == 1
                imageName = sprintf('%s.png', group.Type);
            else
                imageName = sprintf('%s_%d.png', group.Type, pageIndex);
            end
            fig = drawAllColorMap(pageGroup, wxyz_cmapdata.fullNames);
            printFigureAndClose(fig, fullfile(picFolder, imageName));
        end
        fprintf('[wxyz_colormap] Rendered "%s": %d maps, %d file(s).\n', group.Type, mapCount, pageCount);
    end
end

function printFigureAndClose(fig, imageFile)
    cleanup = onCleanup(@() closeFigureIfValid(fig));
    print(fig, imageFile, '-dpng', '-r300', '-image');
end

function closeFigureIfValid(fig)
    if isgraphics(fig)
        close(fig);
    end
end

function fig = drawAllColorMap(cmapstruct, cmapNames)
    cmapList = [cmapstruct.Colors];
    numCmaps = numel(cmapList);
    numRows = ceil(sqrt(numCmaps));
    numCols = ceil(numCmaps / numRows);
    if numCols < 7
        numCols = 7;
        numRows = max(5, ceil(numCmaps/numCols));
    end
    if numCmaps <= 100
        fig = wxyz_figure(numRows, numCols, 'Position', [0 100 2000 1000], 'Visible', 'off');
    else
        fig = wxyz_figure(numRows, numCols, 'Position', [0 100 6000 2000], 'Visible', 'off');
    end
    for i = 1:numCmaps
        nexttile;
        cmap = double(cmapList{i})./255;
        imagesc(1:256);
        colormap(gca, cmap);
        set(gca, 'ytick', [], 'xtick', []);
        cmapidx = find(strcmpi(cmapstruct.Names{i}, cmapNames));
        % title(strcat(['[', num2str(cmapidx), ']-'], cmapstruct.Names{i}), 'FontSize', 12, 'Interpreter', 'none');
        title(cmapstruct.Names{i}, 'FontSize', 12, 'Interpreter', 'none');
        ylabel(['[', num2str(cmapidx), ']']);
        axis tight;
        % axis off;
    end
    wxyz_decorFigure(fig);
end
