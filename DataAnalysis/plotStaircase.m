function plotStaircase(centerArray, peripheryArray)

trials = 1:100;

linespec = '- .';
width = 2;
size = 10;
minY = 0;
maxY = 1;


plot(trials, centerArray, linespec, 'LineWidth', width, 'MarkerSize', size);
hold on;
plot(trials, peripheryArray, linespec, 'LineWidth', width, 'MarkerSize', size);
ylim([minY maxY]);

