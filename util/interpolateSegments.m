function [segments_interp, M] = interpolateSegments(segments,size)

M = zeros(size,size);

for i=1:length(segments)
    curSeg = segments{i};
    
    curSeg_interp = [];
    for j=1:length(curSeg)-1
        x1 = curSeg(j,1);
        x2 = curSeg(j+1,1);
        y1 = curSeg(j,2);
        y2 = curSeg(j+1,2);
        
        xdiff = abs(x1-x2);
        ydiff = abs(y1-y2);
        xmin = min(x1,x2);
        ymin = min(y1,y2);
        xmax = max(x1,x2);
        ymax = max(y1,y2);
        
        if xdiff > ydiff
            xi = [xmin:xmax]';
            yi = interp1([x1 x2], [y1 y2], xi);
        else
            yi = [ymin:ymax]';
            xi = interp1([y1 y2], [x1 x2], yi);
        end
        curSeg_interp = [curSeg_interp; round([xi yi])];
    end
    
    segments_interp{i} = curSeg_interp;
    for j=1:length(curSeg_interp)
        M(curSeg_interp(j,2),curSeg_interp(j,1)) = 1;    
    end
end