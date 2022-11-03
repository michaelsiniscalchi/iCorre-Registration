function fig = fig_mvtCorrMetrics(session_ID, R, crispness, mean_projection)

fig = figure('Name',[session_ID, '_movement correction metrics'],...
    'Units','normalized','Position',[0.1,0.1,0.5,0.8]);

nCols = numel(fieldnames(mean_projection))*5;
tiledlayout(10,nCols,"TileSpacing","tight");

% Mean Projection with crispness as annotation 
fields = fieldnames(mean_projection);
for i = 1:numel(fields)
    ax(i) = nexttile((i*5)-4,[5,5]);
    imagesc(mean_projection.(fields{i}));
    title(['Mean (' fields{i} ' stack)']);
    set(ax(i),'XTickLabel',[],'YTickLabel',[]);
    text(1,-0.05,['Crispness = ',num2str(crispness.(fields{i}),4)],...
        'Units','normalized','HorizontalAlignment','right');
    text(1,-0.1,['Mean R, frame(i) vs. mean img. = ',num2str(R.mean.(fields{i}),2)],...
        'Units','normalized','HorizontalAlignment','right');
    axis square
end

ax(3) = nexttile(nCols*6+1,[2,10]);
c = ax(3).ColorOrder;
y = 1;
for i = 1:numel(fields)
    p(i) = plot(R.(fields{i}),"Color",c(i,:)); hold on;
    ylabel('R');
    xlabel('Frame Index');
    text(1.05,y,(fields{i}),'Color',c(i,:),'Units','normalized','HorizontalAlignment','right');
    y = y-0.2;
end
title('Correlation with mean projection');
