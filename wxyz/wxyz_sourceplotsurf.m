function [hdlsurf, hdlbrain, hdlscalp] = wxyz_sourceplotsurf(data, sourcemodel, varargin) % sourcemodel, data, roi, scalp, iscb, viewangle
%WXYZ_SOURCEPLOTSURF This function is used to plot brain activity on a 3D brain surface model.
%
% This function visualizes brain activity data overlaid on a brain
% structural model, allowing for customization of regions of interest,
% scalp representation, colorbar visibility, and view angle via optional
% key-value pair arguments.
%
%   data        - A vector of brain activity data that will be mapped onto
%               the sourcemodel. Typically, data should be preprocessed and
%               normalized.
%
%   sourcemodel - A structure representing the brain's anatomical model,
%               required for overlaying the activity data. It should be a
%               file or a variable previously loaded that includes
%               coordinates and possibly triangulation.
%
%   varargin    - Optional key-value pairs for additional settings:
%       'roi'   - Specifies regions of interest on the brain to focus the plot.
%       'scalp' - A structure representing the scalp's anatomical model.
%       'cbar'  - Boolean value to toggle the display of a color bar (default is false).
%       'view'  - Array of two elements [azimuth, elevation] for setting the view angle.
%
% Example:
%   figHandle = wxyz_sourceplotsurf(data, sourcemodel, 'brainroi', roi,
%               'scalp', true, 'colorbar', true, 'view', [90, 0]);
%
% Author: wxyz
% Version: 1.0
% Last revision date: 2024-04-16


% everything is added to the current figure
holdflag = ishold;
if ~holdflag
  hold on
end

roi         = ft_getopt(varargin, 'roi',        []);
plotbrain   = ft_getopt(varargin, 'plotbrain',  true);
brainalpha  = ft_getopt(varargin, 'brainalpha', 0.3);
scalp       = ft_getopt(varargin, 'scalp',      []);
scalpalpha  = ft_getopt(varargin, 'scalpalpha', 0.3);
cbar        = ft_getopt(varargin, 'colorbar',   false);
cbartitle   = ft_getopt(varargin, 'colorbarlabel',      []);
cbartitleori= ft_getopt(varargin, 'colorbarlabelori',   90);
cbarlocation= ft_getopt(varargin, 'colorbarlocation',   'eastoutside');
cmap        = ft_getopt(varargin, 'colormap',   wxyz_colormap(1));
viewangle   = ft_getopt(varargin, 'view',       [-90 90]);
setpivot    = ft_getopt(varargin, 'setpivot',   true);
pivot       = ft_getopt(varargin, 'pivot',      0);

% Check data
if numel(sourcemodel.brainstructure) ~= numel(data) && numel(roi) ~= numel(data)
    error('The length of data should be the same as the number of voxels in the sourcemodel or the number of voxels in the roi.');
end

isplotroi = ~isempty(roi);
isdataroi = isplotroi & (numel(roi) == numel(data));
isplotscalp = ~isempty(scalp);

% Do plot
if ~isplotroi
    if plotbrain && any(isnan(data))
        hdlbrain = ft_plot_mesh(sourcemodel);
        set(hdlbrain, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', brainalpha);
    end
    hdlsurf = ft_plot_mesh(sourcemodel, 'vertexcolor', data);
    set(gca, 'Clim', [min(data) max(data)]); % Change color limit
else
    datatmp = nan(numel(sourcemodel.brainstructure), 1);
    if isdataroi
        datatmp(roi) = data;
    else
        datatmp(roi) = data(roi);
    end
    if plotbrain
        hdlbrain = ft_plot_mesh(sourcemodel);
        set(hdlbrain, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', brainalpha);
    end
    hdlsurf = ft_plot_mesh(sourcemodel, 'vertexcolor', datatmp);
    set(gca, 'Clim', [min(datatmp) max(datatmp)]); % Change color limit
end
if isplotscalp
    hdlscalp = ft_plot_mesh(scalp, 'vertexcolor', ones(size(scalp.pos, 1), 1));
    set(hdlscalp, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', scalpalpha);
end
if cbar
    cb = colorbar('location', cbarlocation);
    set(cb.Label, 'String', cbartitle, 'Rotation', cbartitleori, 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center');
end
colormap(gca, cmap);
view(viewangle);
% light;
% light('Position',[1 0 0]);
% light('Position',[0 1 0]);
% light('Position',[0 0 1]);
lighting gouraud;
material dull;
% camlight;
if setpivot
    wxyz_setPivot(gca, pivot);
end

axis off
axis vis3d
axis equal

if ~holdflag
  hold off
end

if ~nargout
  clear hdlbrain hdlscalp
end


% if nargin == 2
%     if numel(sourcemodel.brainstructure) == numel(data)
%         hdlroi = ft_plot_mesh(sourcemodel, 'vertexcolor', data);
%     else
%         error('The number of elements in data does not match the number of elements in the sourcemodel.');
%     end
% elseif ~isempty(find(ismember(3:6, nargin), 1)) % nargin == 3 || nargin == 4 || nargin == 5 || nargin
%     if numel(brainroi) == numel(data)
%         dattmp = nan(numel(sourcemodel.brainstructure), 1);
%         dattmp(brainroi) = data;
%         hdlbrain = ft_plot_mesh(sourcemodel, 'vertexcolor', dattmp);
%         set(hdlbrain, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.3);
%         hdlroi = ft_plot_mesh(sourcemodel, 'vertexcolor', dattmp);
%     else
%         error('The number of elements in data does not match the number of elements in the roi.');
%     end
%     if nargin == 4 || nargin == 5 || nargin == 6 && ~isempty(scalp)
%         hold on
%         hdlscalp = ft_plot_mesh(scalp, 'vertexcolor', ones(size(scalp.pos, 1), 1));
%         set(hdlscalp, 'FaceColor', [0.8 0.8 0.8], 'FaceAlpha', 0.3);
%     end
%     if nargin == 5 || nargin == 6 && iscb
%         colorbar;
%     end
%     colormap(wxyz_colormap(1));
%     if nargin == 6
%         view(viewangle(1), viewangle(2));
%     else
%         view(90, viewangle(2));
%     end
%     set(gca, 'CLim', [min(dattmp) max(dattmp)]);
%     wxyz_setPivot(gca, 0);
%     light;
%     lighting gouraud;
%     material dull;
% else
%     error('The number of input variables is incorrect!');
% end
% 
% axis off
% axis vis3d
% axis equal
% 
% if ~holdflag
%   hold off
% end
% 
% if ~nargout
%   clear hdlroi hdlscalp
% end