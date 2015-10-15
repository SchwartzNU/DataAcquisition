function tex = textureGenerator(sizeX, sizeY, sigma, seed)
winL = 200; %size of smoothing factor window
rng(seed); %set random seed
M = rand(sizeX,sizeY);
if sigma>0
    win = fspecial('gaussian',winL,sigma);
    win = win ./ sum(win(:));
    M = imfilter(M,win,'replicate');
    M = M./max(M(:));
else
    %do nothing
end

tex = makeUniformDist(M);
tex = uint8(tex.*255);


