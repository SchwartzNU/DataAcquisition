function M = thresholdMaskImage(fname,channel,stdThres,rotation)
%rotation in degrees
%fname is either name of image file or actual image

if ischar(fname) %read file
    M_orig = imread(fname);
else %just use input
    M_orig = fname;
end
if ndims(M_orig) == 3
    M_ch = squeeze(M_orig(:,:,channel));
else
    M_ch = M_orig;
end

[x,y] = size(M_ch);

%M = edge(M_ch);
M_ch = wiener2(M_ch,[9,9]);

M_flat = reshape(double(M_ch),x*y,1);
th = mean(M_flat) + stdThres*std(M_flat);
M = M_ch;
M(M_ch<th) = 0;
M(M_ch>=th) = 1;

if rotation == 90
   M = rot90(M); 
elseif rotation == 180
   M = rot90(M,2);
end


