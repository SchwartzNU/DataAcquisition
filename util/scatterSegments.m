function [] = scatterSegments(segments,scale)

%h = figure;
ax = gca;
L = length(segments);
hold(ax, 'on');
for i=1:L
    curSeg = segments{i}.*scale;
    scatter(ax,curSeg(:,1),curSeg(:,2),'k.');
end