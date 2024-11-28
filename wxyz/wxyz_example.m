% wxyz_example
% Test all the function in the 'wxyz' folder

%% wxyz_barplot
x = [1.1 2.2 3.3 4.4];
y = x/2;
y(2)=0;
c = wxyz_color(1, [1 3 7 9]);
fig = wxyz_figure(1, 1, 'Position', [100 100 1000 500]);
nexttile;
wxyz_barplot(x, y, c, 'barwidth', 0.8, 'show0err',false, 'xtick', {'1', '2', '3', '4'}, 'legend', {'1', '2', '3', '4'});
wxyz_decorFigure(fig);
title('wxyz barplot 1 condition');

x = [1.1 2.2 3.3 4.4; 2.1 3.2 4.3 5.4];
y = x/2;
y(1,3) = 0;
y(2,2)=0;
c = wxyz_color(1, [1 3 7 9]);
fig = wxyz_figure(1, 1, 'Position', [100 100 1000 500]);
nexttile;
wxyz_barplot(x, y, c, 'barwidth', 0.8, 'show0err', false, 'xtick', {'1', '2', '3', '4'}, 'legend', {'1', '2', '3', '4'})
wxyz_decorFigure(fig);
title('wxyz barplot 2 conditions');

%% wxyz_barscatterplot
rng
group = 7;
sample = 5;
x = cat(3, rand(group,1)*ones(1,sample).*2+rand(group,sample)./3.5, rand(group,1)*ones(1,sample).*2+rand(group,sample)./3.5);
x(3, :, 1) = ones(1, 5); % test 0 std
fig = wxyz_figure(1, 1, 'Position', [100 100 1000 500]);
nexttile;
wxyz_barscatterplot(x, 'barwidth', 0.9, 'show0err', false,...
    'xtick', {'x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7'}, 'legend', {'X', 'Y'}, 'xlabel', 'XLabel', 'ylabel', 'YLabel', ...
    'facecolor', wxyz_color(1, [3 7]), 'facealpha', 0.6, 'errortype', 'std', ...
    'showmarker', true, 'markersize', 100, 'markeredgeColor', 'k');
wxyz_decorFigure(fig);