function [roi, roiL, roiR] = wxyz_selectbrainroi(brainatlasL, brainatlasR, roiidx, varargin)
%WXYZ_SELECTBRAINROI This function selects regions of interest (ROI) from brain atlases for left and right hemispheres.
%
% This function extracts specified regions of interest from provided brain
% atlases of the left and right hemispheres based on indices. It allows for
% optional adjustments such as extending ROIs, and including specific
% source models through key-value pairs.
%
%   brainatlasL  - Brain atlas for the left hemisphere, containing various
%                  brain region partitions.
%   brainatlasR  - Brain atlas for the right hemisphere, similar to
%                  brainatlasL but for opposite hemisphere.
%   roiidx       - Indices of the regions of interest in the brain atlas. 
%                  These should correspond to regions in both left and
%                  right hemisphere atlases.
%
%   varargin     - Optional key-value pairs for additional customization:
%       'sourcemodel' - The 3D model of the brain used for aligning or visualizing the ROIs.
%       'isextend'    - Boolean value indicating whether to extend the selected ROI (true extends).
%       'roi4extend'  - Additional ROI indices to extend into the initial selection, if 'isextend' is true.
%       'iteration'   - Number of iterations to perform any extending operation, if applicable.
%
% Outputs:
%   roi     - The extracted ROI from the all brain atlas.
%   roiL    - The extracted ROI from the left hemisphere brain atlas.
%   roiR    - The extracted ROI from the right hemisphere brain atlas.
%
% Example:
%   [roi, roiL, roiR] = wxyz_selectbrainroi(brainatlasL, brainatlasR, roiidx, ...
%                       'sourcemodel', sourcemodel, 'isextend', true, ...
%                       'roi4extend', [16 21 23], 'iteration', 1);
%
% Author: wxyz
% Version: 1.0
% Last revision date: 2024-04-16


% do the general setup of the function
ft_defaults

% Default value
sourcemodel = ft_getopt(varargin, 'sourcemodel', []);
isextend    = ft_getopt(varargin, 'isextend',    false);
roi4extend  = ft_getopt(varargin, 'roi4extend',  []);
iteration   = ft_getopt(varargin, 'iteration',   1);
isplot      = ft_getopt(varargin, 'isplot',      false);

if ~isempty(sourcemodel)
    atlastmpL = brainatlasL;
    atlastmpR = brainatlasR;
    sourcemodelL = sourcemodel; sourcemodelL.pos = sourcemodel.pos(sourcemodel.brainstructure == 1, :);
    sourcemodelL.tri = sourcemodel.tri(1:size(sourcemodel.tri,1)/2, :);
    sourcemodelR = sourcemodel; sourcemodelR.pos = sourcemodel.pos(sourcemodel.brainstructure == 2, :);
    sourcemodelR.tri = sourcemodel.tri(size(sourcemodel.tri,1)/2+1:end, :)-numel(atlastmpL.parcellation);
end

if isplot
    figure; hold on;
    ft_plot_mesh(sourcemodel, 'vertexcolor', sourcemodel.thickness);
end

% Find roi
if ~isextend
    roiL = find(ismember(brainatlasL.parcellation, roiidx));
    roiR = find(ismember(brainatlasR.parcellation, roiidx)) + numel(brainatlasL.parcellation);
else % Do extend
    if ~isempty(sourcemodel) && ~isempty(roi4extend) && iteration~=0
        for r = 1:numel(roiidx)
            % prepare tmp
            for iter = 1:iteration
                pL_neighb = [];
                pR_neighb = [];
                pL_src = find(ismember(atlastmpL.parcellation, roiidx(r)));
                pR_src = find(ismember(atlastmpR.parcellation, roiidx(r)));
                [LiaL_src, ~] = ismember(sourcemodelL.tri, pL_src);
                [LiaR_src, ~] = ismember(sourcemodelR.tri, pR_src);
                for r_ex = 1:numel(roi4extend)
                    pL_tar = find(atlastmpL.parcellation == roi4extend(r_ex));
                    pR_tar = find(atlastmpR.parcellation == roi4extend(r_ex));
                    [LiaL_tar, ~] = ismember(sourcemodelL.tri, pL_tar);
                    [LiaR_tar, ~] = ismember(sourcemodelR.tri, pR_tar);
                    pL_neighb = cat(1, pL_neighb, find(sum(LiaL_src, 2)>0 & sum(LiaL_src, 2)<3 & sum(LiaL_tar, 2)>0 & sum(LiaL_tar, 2)<3));
                    pR_neighb = cat(1, pR_neighb, find(sum(LiaR_src, 2)>0 & sum(LiaR_src, 2)<3 & sum(LiaR_tar, 2)>0 & sum(LiaR_tar, 2)<3));
                end
                tmpL = unique(reshape(sourcemodelL.tri(pL_neighb,:), [numel(sourcemodelL.tri(pL_neighb, :)), 1]));
                tmpR = unique(reshape(sourcemodelR.tri(pR_neighb,:), [numel(sourcemodelR.tri(pR_neighb, :)), 1]));
                pL_ext = setdiff(tmpL, pL_src);
                pR_ext = setdiff(tmpR, pR_src);
                atlastmpL.parcellation(pL_ext) = roiidx(r);
                atlastmpR.parcellation(pR_ext) = roiidx(r);
            end
        end
        
        % output
        roiL = find(ismember(atlastmpL.parcellation, roiidx));
        roiR = find(ismember(atlastmpR.parcellation, roiidx)) + numel(brainatlasL.parcellation);
        
    else
        error('Please check the inputs for extend roi.');
    end
end

if ~isempty(sourcemodel) && isplot
    ft_plot_mesh(sourcemodelL.pos(ismember(atlastmpL.parcellation, roiidx), :), 'vertexcolor', 'k');
    ft_plot_mesh(sourcemodelR.pos(ismember(atlastmpR.parcellation, roiidx), :), 'vertexcolor', 'r');
end

% 
% 
% if nargin == 7 && isExtend == 1 % extend roi
%     % prepare tmp
%     atlastmpL = brainatlasL; atlastmpR = brainatlasR;
%     sourcemodelL = sourcemodel; sourcemodelL.pos = sourcemodel.pos(sourcemodel.brainstructure == 1, :); sourcemodelL.tri = sourcemodel.tri(1:size(sourcemodel.tri,1)/2, :);
%     sourcemodelR = sourcemodel; sourcemodelR.pos = sourcemodel.pos(sourcemodel.brainstructure == 2, :); sourcemodelR.tri = sourcemodel.tri(size(sourcemodel.tri,1)/2+1:end, :)-numel(atlastmpL.parcellation);
%     
% %     figure; hold on;
% %     ft_plot_mesh(sourcemodel, 'vertexcolor', sourcemodel.thickness);
%     for iter = 1:iteration
%         pL_neighb = [];
%         pR_neighb = [];
%         pL_src = find(atlastmpL.parcellation == roiidx);
%         pR_src = find(atlastmpR.parcellation == roiidx);
%         [LiaL_src, ~] = ismember(sourcemodelL.tri, pL_src);
%         [LiaR_src, ~] = ismember(sourcemodelR.tri, pR_src);
%         for r = 1:numel(roi2extend)
%             pL_tar = find(atlastmpL.parcellation == roi2extend(r));
%             pR_tar = find(atlastmpR.parcellation == roi2extend(r));
%             [LiaL_tar, ~] = ismember(sourcemodelL.tri, pL_tar);
%             [LiaR_tar, ~] = ismember(sourcemodelR.tri, pR_tar);
%             pL_neighb = cat(1, pL_neighb, find(sum(LiaL_src, 2)>0 & sum(LiaL_src, 2)<3 & sum(LiaL_tar, 2)>0 & sum(LiaL_tar, 2)<3));
%             pR_neighb = cat(1, pR_neighb, find(sum(LiaR_src, 2)>0 & sum(LiaR_src, 2)<3 & sum(LiaR_tar, 2)>0 & sum(LiaR_tar, 2)<3));
%         end
%         tmpL = unique(reshape(sourcemodelL.tri(pL_neighb,:), [numel(sourcemodelL.tri(pL_neighb, :)), 1]));
%         tmpR = unique(reshape(sourcemodelR.tri(pR_neighb,:), [numel(sourcemodelR.tri(pR_neighb, :)), 1]));
%         pL_ext = setdiff(tmpL, pL_src);
%         pR_ext = setdiff(tmpR, pR_src);
%         atlastmpL.parcellation(pL_ext) = roiidx;
%         atlastmpR.parcellation(pR_ext) = roiidx;
%     end
% %     ft_plot_mesh(sourcemodelL.pos(atlastmpL.parcellation==roiidx, :), 'vertexcolor', 'k');
% %     ft_plot_mesh(sourcemodelR.pos(atlastmpR.parcellation==roiidx, :), 'vertexcolor', 'r');
% 
%     % output
%     roiL = [];
%     roiR = [];
%     
%     roiL = cat(1, roiL, find(atlastmpL.parcellation==roiidx));
%     roiR = cat(1, roiR, find(atlastmpR.parcellation==roiidx) + numel(brainatlasL.parcellation));
% end

% Append roiL and roiR
roi = cat(1, roiL, roiR);

