function [XI,YI,Znew] = resample3DFunc(x,y,z,N)

minVal = min([x y]);
maxVal = max([x y]);

minVal = 0;

X = linspace(minVal, maxVal, N);

[XI, YI] = meshgrid(X,X);

Znew = griddata(x,y,z,XI,YI);