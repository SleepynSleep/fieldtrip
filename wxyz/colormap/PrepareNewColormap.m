clc;clear;close all hidden;
ft_defaults;

%% colormap
wxyz_cmapdata = load('C:\Users\WangXu\Desktop\slanColor-master\slanCM\slanCM_Data.mat');
wxyz_cmapdata = rmfield(wxyz_cmapdata, 'author');
wxyz_cmapdata.colormap = wxyz_cmapdata.slandarerCM;
wxyz_cmapdata = rmfield(wxyz_cmapdata, 'slandarerCM');
wxyz_cmapdata.fullNames = wxyz_cmapdata.fullNames';

tmp = struct('fullNames', [], 'colormap', struct('Type', 'wxyz', 'Names', [], 'Colors', []));
for i = 1:numel(wxyz_color_old)
    tmp.fullNames = cat(1, tmp.fullNames, {strcat('wxyz_', num2str(i))});
    tmp.colormap(end).Names = cat(2, tmp.colormap(end).Names, {strcat('wxyz_', num2str(i))});
    tmp.colormap(end).Colors = cat(2, tmp.colormap(end).Colors, {wxyz_colormap(i)});
end

wxyz_cmapdata.fullNames = cat(1, tmp.fullNames, wxyz_cmapdata.fullNames);
wxyz_cmapdata.colormap = [tmp.colormap wxyz_cmapdata.colormap];

save('D:\MATLAB\R2023b\toolbox\fieldtrip\wxyz\wxyz_cmapdata.mat', 'wxyz_cmapdata');

%% color
wxyz_cdata = load('C:\Users\WangXu\Desktop\slanColor-master\slanCL\slanCL_Data.mat');
wxyz_cdata = rmfield(wxyz_cdata, 'Author');

tmp = struct('Package', [], 'Palette', [], 'Length', [], 'Type', [], 'Key', [], 'Name', [], 'Color', [], 'PackageInd', []);
tmp.Name = {'wxyz'};
for i = 1:numel(wxyz_color_old)
    tmp.Package = cat(2, tmp.Package, {'wxyz'});
    tmp.Palette = cat(2, tmp.Palette, {'wxyz'});
    tmp.Length  = cat(2, tmp.Length,  {size(wxyz_color_old(i), 1)});
    tmp.Type    = cat(2, tmp.Type, {'wxyz'});
    tmp.Key     = cat(2, tmp.Key, {strcat('wxyz::wxyz_', num2str(i))});
    tmp.Color   = cat(2, tmp.Color, {wxyz_color_old(i)});
    tmp.PackageInd = cat(2, tmp.PackageInd, find(strcmpi(tmp.Name, 'wxyz')));
end

wxyz_cdata.Name     = cat(2, tmp.Name, wxyz_cdata.Name);
wxyz_cdata.Package  = cat(2, tmp.Package, wxyz_cdata.Package);
wxyz_cdata.Palette  = cat(2, tmp.Palette, wxyz_cdata.Palette);
wxyz_cdata.Length   = cat(2, tmp.Length, wxyz_cdata.Length);
wxyz_cdata.Type     = cat(2, tmp.Type, wxyz_cdata.Type);
wxyz_cdata.Key      = cat(2, tmp.Key, wxyz_cdata.Key);
wxyz_cdata.Color    = cat(2, tmp.Color, wxyz_cdata.Color);
wxyz_cdata.PackageInd = cat(2, tmp.PackageInd, wxyz_cdata.PackageInd+1);

save('D:\MATLAB\R2023b\toolbox\fieldtrip\wxyz\wxyz_cdata.mat', 'wxyz_cdata');