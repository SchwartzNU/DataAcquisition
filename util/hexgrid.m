function [X,Y] = hexgrid(planeSize,spacing,randPhase)

gridSize = ceil((planeSize./spacing) * 1.5);
if rem(gridSize,2) == 1, gridSize = gridSize+1; end

Rad3Over2 = sqrt(3) / 2;
[X Y] = meshgrid(1:1:gridSize);
n = size(X,1);
X = Rad3Over2 * X;
Y = Y + repmat([0 0.5],[n,n/2]);

%set spacing
X = X * spacing;
Y = Y * spacing;

Ind = (X-spacing*2 <= planeSize & Y-spacing*2 <= planeSize);
X = X(Ind);
Y = Y(Ind);

if randPhase
    %adding random noise
    %rand('seed',1);
    L = length(X);
    X = X+spacing./2.*(rand(L,1)-0.5);
    Y = Y+spacing./2.*(rand(L,1)-0.5);
end

%X,Y are now coordinates of bipolar centers
% bpCenters = [X, Y];
% nBipolars = numel(X);
