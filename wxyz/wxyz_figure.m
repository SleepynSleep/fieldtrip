function [hFig, hTiled] = wxyz_figure(rows, cols, varargin)
% WXYZ_FIGURE This function implements a figure that creates a tiledlayout
% containing the specified number of grids. 
% 
% This function accepts the input parameters rows and cols, as well as
% other parameters used by the configure function, and returns the created
% figure handle.
% 
% rows  - the first input parameter, should be a positive integer.
% cols  - the second input parameter, should be a positive integer.
% 
% hFig  - the created figure handle.
%
% example:
%   hFig = wxyz_figure(2, 2, 'Name', 'My Custom Figure', 'Position', [0 0 1000 1000]);
% 
% Author: wxyz
% Version: 1.0
% Last revision date : 2024-01-05

% Code implementation section
hFig = figure(varargin{:}); % Creates a figure and passes all parameters except rows and columns.
set(hFig, 'Color', 'white'); % Change the background to white.
hTiled = tiledlayout(hFig, rows, cols, 'TileSpacing', 'compact', 'Padding', 'compact'); % call tiledlayout with parameter rows and cols.
