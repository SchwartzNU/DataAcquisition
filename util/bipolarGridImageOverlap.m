function [fractionWithin, fractionBetween] = bipolarGridImageOverlap(im1,im2,bipolarSpacing,overlapThres,imagePixel,Ntrials)

L = size(im1,1);
spacing_pix = round(bipolarSpacing./imagePixel);
[x1,y1] = find(im1>0);
[x2,y2] = find(im2>0);
fractionWithin = zeros(Ntrials,1);
fractionBetween = zeros(Ntrials,1);

for n=1:Ntrials
    [bpX,bpY] = hexgrid(L,spacing_pix,1);
    nBp = length(bpX);
    closestPoint1 = zeros(1,nBp);
    closestPoint2 = zeros(1,nBp);
    for i=1:nBp
       D1 = sqrt((bpX(i) - x1).^2 + (bpY(i) - y1).^2);
       D2 = sqrt((bpX(i) - x2).^2 + (bpY(i) - y2).^2);
       closestPoint1(i) = min(D1);
       closestPoint2(i) = min(D2);        
    end    
    closestPoint1 = closestPoint1*imagePixel;
    closestPoint2 = closestPoint2*imagePixel;
    
    outsideBothInd = closestPoint1>overlapThres & closestPoint2>overlapThres;
    closestPoint1 = closestPoint1(~outsideBothInd);
    closestPoint2 = closestPoint2(~outsideBothInd);
    N = length(closestPoint1);
    insideBothInd = closestPoint1<=overlapThres & closestPoint2<=overlapThres;
    insideOneInd = (closestPoint1<=overlapThres & closestPoint2>overlapThres) | (closestPoint1>overlapThres & closestPoint2<=overlapThres);
    fractionWithin(n) = sum(insideBothInd) ./ N;
    fractionBetween(n) = sum(insideOneInd) ./ N;    
end
    

