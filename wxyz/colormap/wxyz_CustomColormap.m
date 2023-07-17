%% Custom colormap
clc;clear;close all;

%%
wxyzColor = {
    [016 070 128;
    049 124 183;
    109 173 209;
    182 215 232;
    233 241 244;
    251 227 213;
    246 178 147;
    220 109 087;
    183 034 048;
    109 001 031]/255; % Color1

    [022 048 074;
    019 103 131;
    033 158 188;
    144 201 231;
    254 183 005;
    255 158 002;
    250 134 000]/255; % Color2

    [002 038 062;003 050 080;013 076 109;115 186 214;
%     013 076 109;
%     003 050 080;
%     002 038 062;
    239 065 067;
    191 030 046;
    196 050 063]/255; % Color3

    [002 048 071;
    018 104 131;
    039 158 188;
    144 201 230;
    252 158 127;
    247 091 065;
    213 033 032]/255; % Color4

    [038 070 083;
    040 114 113;
    042 157 140;
    138 176 125;
    233 196 107;
    243 162 097;
    230 111 081]/255; % Color5

    [255 255 255;
    251 227 213;
    246 178 147;
    220 109 087;
    183 034 048;
    109 001 031]/255; % Color6
    
    [016 070 128;
    049 124 183;
    109 173 209;
    182 215 232;
    233 241 244;
    255 255 255]/255; % Color7
    };

wxyzColormap = cell(size(wxyzColor));

%% Generate
N = 256;
for c = 1:length(wxyzColor)
    wxyzColormap{c} = GenColormap(wxyzColor{c}, N);
end

%% Save
save('wxyzColor.mat', 'wxyzColor');
save('wxyzColormap.mat', 'wxyzColormap');
CustomColor = [];
for c = 1:length(wxyzColor)
    eval(['CustomColor.Color' num2str(c) '=wxyzColor{c}']);
    eval(['CustomColor.Colormap' num2str(c) '=wxyzColormap{c}']);
end

%%
h = figure('Position', [100 100 1600 100]);
tiledlayout(1, 7, 'TileSpacing', 'compact', 'Padding', 'compact');
for c = 1:length(wxyzColor)
    nexttile;
    image(permute(wxyzColormap{c}, [3,1,2])); axis off;
    title(['No.' num2str(c)], 'FontName', 'Times New Roman', 'FontSize', 10, 'FontWeight', 'bold');
end
print(h, 'Example', '-dpng', '-r300', '-image')

%% Function GenColormap
function colormap = GenColormap(map, n)
    m = size(map, 1);
    if m >= n
        colormap = map;
    else
        % 范围重置
        range = 0 : m-1;
        range = range*(n-1)/(m-1) + 1;
        % 插值
        colormap = nan(n, 3);
        for i = 1:3
            colormap(:, i) = interp1(range, map(:, i), 1:n);
        end
    end
end

%% Function Test Colormap
function testColor(c, c_idx1, c_idx2,  map)
    figure('Position', [100 100 1200 300]);
    tiledlayout(1, 3, 'TileSpacing','compact','Padding','compact');
    
    %% Histogram
    nexttile;
    data_mean   = [212, 238, 250, 220]; %均值
    data_std    = [56, 65, 59, 62]; %标准差
    RGB = [c(c_idx1(1),:); c(c_idx1(2),:); c(c_idx1(3),:); c(c_idx1(4),:)];
    y = data_mean; 
    neg = data_std; 
    pos = data_std; 
    n = size(y,2);
    x = 1 : n;
    h = bar(x, y);
    for j = 1 : n
        h.FaceColor = 'flat';
        h.CData(j,:) = RGB(j,:);
        h.EdgeColor = 'flat';
    end
    xx = h.XEndPoints;
    hold on
    errorbar(xx, y, neg, pos, 'LineStyle', 'none', 'Color', 'k', 'LineWidth', 1);
    set(gca, 'XTickLabel', {'S1', 'S2', 'S3', 'S4'});
    ylabel('Amplitude (fT)');
    set(gca, 'FontSize', 12, 'FontName', 'Times New Roman');
    set(gca, 'XColor', 'k', 'YColor', 'k', 'linewidth',1);
    ylim([0 350]); box off;

    %% Line Chart
    nexttile;
    hold on;
    data = [14 24 63 36;
            82 19 90 53
            67 90 33 43
            47 71 76 18
            24 39 14 52
            37 24 26 83
            64 47 83 18
            70 69 55 24];
    plot(data(:, 1), 'Marker', 'o', 'Color', c(c_idx2(1), :), 'LineWidth', 2);
    plot(data(:, 2), 'Marker', '^', 'Color', c(c_idx2(2), :), 'LineWidth', 2);
    plot(data(:, 3), 'Marker', 's', 'Color', c(c_idx2(3), :), 'LineWidth', 2);
    plot(data(:, 4), 'Marker', 'v', 'Color', c(c_idx2(4), :), 'LineWidth', 2);
    xlim([0 9]); ylim([0 100]);
    xlabel('Points');
    ylabel('Amplitude (fT)');
    set(gca, 'FontSize', 12, 'FontName', 'Times New Roman');
    set(gca, 'XColor', 'k', 'YColor', 'k', 'linewidth',1);
    legend('Location', 'northeast')
    box off;
    
    %% Peaks
    nexttile;
    surf(peaks);
    colormap(map);
    shading interp
    xlabel('x'); ylabel('y'); zlabel('z');
    set(gca, 'FontSize', 12, 'FontName', 'Times New Roman');
    set(gca, 'XColor', 'k', 'YColor', 'k', 'linewidth',1);
    box off;

end
