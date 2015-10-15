function M = skeletonToXYMatrix(skel,rotation,pixX,pixY,micronsPerPixel)
%rotation in degrees
%fname is either name of image file or actual image

M = zeros(pixX,pixY);


XY = skel.FilStats.aXYZ(:,1:2);
nPoints = size(XY,1);

Xoffset = micronsPerPixel.*pixX/2;
Yoffset = micronsPerPixel.*pixX/2;

XY(:,1) = XY(:,1) + Xoffset;
XY(:,2) = XY(:,2) + Yoffset;

XY = XY./micronsPerPixel;
XY = round(XY);

for i=1:nPoints
   M(XY(i,2),XY(i,1)) = 1; 
end

if rotation == 90
   M = rot90(M); 
elseif rotation == 180
   M = rot90(M,2);
end


