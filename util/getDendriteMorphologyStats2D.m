function varTheta = getDendriteMorphologyStats2D(segments,centerPoint)
allEdges = [];
for i=1:length(segments)
    curSeg = segments{i};
    for j=1:size(curSeg,1)-1
        curEdge = [curSeg(j,:), curSeg(j+1,:)];
        allEdges = [allEdges; curEdge];
    end
end

L = size(allEdges,1);

%in pixels for now
radii = 20:5:100;
R = length(radii);

N = 100;
varTheta = zeros(1,R);
for r=1:R
    radii(r)
    [circX,circY] = circleAsPolygon([centerPoint(1) centerPoint(2) radii(r)], N);
    
    circEdges = [circX(1:N-1) circY(1:N-1) circX(2:N) circY(2:N)];
    
    allIntersections = [];
    for i=1:N-1
        curInt = intersectEdges(allEdges, circEdges(i,:));
        allIntersections = [allIntersections; curInt(~isnan(sum(curInt,2)),:)];        
    end
    [theta, rho] = cart2pol(allIntersections(:,1)-centerPoint(1),allIntersections(:,2)-centerPoint(2));
    varTheta(r) = var(theta);
    keyboard;
end

