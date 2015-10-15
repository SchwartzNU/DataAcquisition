function [] = plotSegments(segments,offsetX,offsetY)

%scaleFactor = 1.5499 / 18;
%scaleFactor = 1.5499 / 30;
scaleFactor = 1;
%h = figure;
ax = gca;
L = length(segments);
hold(ax, 'on');
for i=1:L
    curSeg = segments{i};
    curSeg(:,1) = scaleFactor*curSeg(:,1) + offsetX;
    curSeg(:,2) = scaleFactor*curSeg(:,2) + offsetY;      
    plot(ax,curSeg(:,1),curSeg(:,2),'g','linewidth',2);
    %plot(ax,-curSeg(:,1),-curSeg(:,2),'r','linewidth',2);
end
hold(ax, 'off');