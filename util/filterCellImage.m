function M_smooth = filterCellImage(M,blurStd,pixelSize)
%blurStd in microns
%pixelSize in microns/pixel

winSize = 200;

win = fspecial('gaussian',winSize,blurStd/pixelSize);
win = win ./ sum(win(:));
M_smooth = imfilter(double(M),win,'replicate');