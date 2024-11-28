% wxyz_functiontest
% Test all the function in the 'wxyz' folder

%% wxyz_barscatterplot
rng
group = 7;
sample = 5;
x = cat(3, rand(group,1)*ones(1,sample).*2+rand(group,sample)./3.5, rand(group,1)*ones(1,sample).*2+rand(group,sample)./3.5);
x(3, :, 1) = ones(1, 5); % test 0 std
fig = wxyz_figure(1, 1, 'Position', [100 100 1000 500]);
nexttile;
wxyz_barscatterplot(x, 'barwidth', 0.9, 'show0err', false, 'xtick', {'x1', 'x2', 'x3', 'x4', 'x5', 'x6', 'x7'}, 'legend', {'X', 'Y'},...
    'facecolor', wxyz_color(1, [3 5]), 'facealpha', 0.6, 'showmarker', true, 'markersize', 100, 'xlabel', 'XLabel', 'ylabel', 'YLabel','errortype', 'std', 'markeredgeColor', 'k');
wxyz_decorFigure(fig)