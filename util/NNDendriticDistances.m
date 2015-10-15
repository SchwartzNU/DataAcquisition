%   CellName(10).name = '121206Hc3';     % check images
%    CellName(11).name = '092006Hc1';       % work on images
%   CellName(12).name = '091807Ac1';


%%

BaseFileName = '032708Ac2';
DataFileName = '032708Ac2';

green(1:64, 1) = 0;
green(1:64, 2) = [1:64] / 64;
green(1:64, 3) = 0;
colormap(green);

ImageFolderPath = '~/data/images/'
RawImageFolderPath = '~/data/images/raw/';
AnalysisFolderPath = '~/analysis/MATLAB/correlated-activity/'

ImageFileName = strcat(ImageFolderPath, strcat(BaseFileName, '.jpg'));
flatim = imread(ImageFileName, 'jpeg');
flatim = edge(flatim);
ImageFileName = strcat(ImageFolderPath, strcat(BaseFileName, 'ch2.jpg'));
flatim2 = imread(ImageFileName, 'jpeg');
flatim2 = edge(flatim2);


%%

%**************************************************************************
% open ics parameters file and extract key information
%**************************************************************************

ImageFileName = strcat(RawImageFolderPath, strcat(BaseFileName, '.ics'));
icsfid = fopen(ImageFileName, 'r');

% get x, y, z size of zstack
TextLine = fgetl(icsfid);
TargetTextLine1 = 'layout';
TargetTextLine2 = 'sizes';
while (isempty(strfind(TextLine, TargetTextLine1)) | isempty(strfind(TextLine, TargetTextLine2)))
    TextLine = fgetl(icsfid);
    if (TextLine == -1)
        break;
    end
end
ImageParameters = sscanf(TextLine(14:length(TextLine)), '%f');
XSize = ImageParameters(3);
YSize = ImageParameters(4);
ZSize = ImageParameters(5);

% get x, y, z step sizes
TextLine = fgetl(icsfid);
TargetTextLine1 = 'parameter';
TargetTextLine2 = 'scale';
while (isempty(strfind(TextLine, TargetTextLine1)) | isempty(strfind(TextLine, TargetTextLine2)))
    TextLine = fgetl(icsfid);
    if (TextLine == -1)
        break;
    end
end
ImageParameters = sscanf(TextLine(18:length(TextLine)), '%f');
XStep = ImageParameters(3);
YStep = ImageParameters(4);
ZStep = abs(ImageParameters(5));

% check whether 2 images (gain1 > 0, gain2 > 0)
TextLine = fgetl(icsfid);
TargetTextLine1 = 'history';
TargetTextLine2 = 'gain1';
while (isempty(strfind(TextLine, TargetTextLine1)) | isempty(strfind(TextLine, TargetTextLine2)))
    TextLine = fgetl(icsfid);
    if (TextLine == -1)
        break;
    end
end
gain1 = sscanf(TextLine(15:length(TextLine)), '%f');
TextLine = fgetl(icsfid);
gain2 = sscanf(TextLine(15:length(TextLine)), '%f');

%%
%**************************************************************************
% open z-stack file and read images into matrix
%**************************************************************************
ImageFileName = strcat(RawImageFolderPath, strcat(BaseFileName, '.ids'));
fid = fopen(ImageFileName, 'r');
clear im im2;
for r = 1:ZSize
    im(:, :, r) = fread(fid, [XSize YSize], 'uint16', 6, 'l');
end

fseek(fid, 2, 'bof');
for r = 1:ZSize
    im2(:, :, r) = fread(fid, [XSize YSize], 'uint16', 6, 'l');
end
fclose(fid);

%%
%**************************************************************************
% open stored image file parameters if applicable
%**************************************************************************
cd (AnalysisFolderPath)
clear CellParameters ImageParameters
DataFile = strcat(DataFileName, 'analysis.mat');
if (exist(DataFile))
    load(DataFile);
end

ImageParameters.Threshold1 = 200;            % min for zstack
ImageParameters.Threshold2 = 180;            % min for zstack
ImageParameters.StartFrame = 10;
ImageParameters.decimatepts = 4;
if (exist('CellParameters'))
    if (isfield(CellParameters, 'ImageParameters'))
        ImageParameters = CellParameters.ImageParameters;
    end
end    

%%

%**************************************************************************
% threshold z-stack to binary image
%**************************************************************************

clear scim;
for r = ImageParameters.StartFrame:ZSize
    tempim = im(:, :, r);
    tempim2 = decimate2d(tempim, ImageParameters.decimatepts);
    indices = find(tempim2 > ImageParameters.Threshold1);
    tempim2(:) = 0;
    tempim2(indices) = 1;
    scim(:, :, r-ImageParameters.StartFrame+1) = tempim2;
end

%**************************************************************************
% make movie of z-stack
%**************************************************************************
clear ZStackMovie
for r = 1:ZSize-ImageParameters.StartFrame
    tempim = scim(:, :, r);
    tempim = tempim * 63 + 1;
    ZStackMovie(r) = im2frame(tempim, green);
end
scrsz = get(0, 'ScreenSize');
figure(1); clf;
set(1, 'Position', [1 scrsz(4)/2 scrsz(3)/2.2 scrsz(4)/1.6]);
movie(ZStackMovie, 2)

%%
%**************************************************************************
% threshold second z-stack to binary image
%**************************************************************************

clear scim2
for r = ImageParameters.StartFrame:ZSize
    tempim = im2(:, :, r);
    tempim2 = decimate2d(tempim, ImageParameters.decimatepts);
    indices = find(tempim2 > ImageParameters.Threshold2);
    tempim2(:) = 0;
    tempim2(indices) = 1;
    scim2(:, :, r-ImageParameters.StartFrame+1) = tempim2;
end

%**************************************************************************
% make movie of second z-stack
%**************************************************************************
clear ZStackMovie
for r = 1:ZSize-ImageParameters.StartFrame
    tempim = scim2(:, :, r);
    tempim = tempim * 63 + 1;
    ZStackMovie(r) = im2frame(tempim, green);
end
scrsz = get(0, 'ScreenSize');
figure(1); clf;
set(1, 'Position', [1 scrsz(4)/2 scrsz(3)/2.2 scrsz(4)/1.6]);
movie(ZStackMovie, 2)

%%
%**************************************************************************
% compute NN distances between each nonzero element of first and second
% images - 3D
%**************************************************************************

zdim = size(scim, 3);

clear coords coords2;
for cnt = 1:zdim
    if (mean(mean(scim(:, :, cnt)) > 0))
        [x, y] = find(scim(:, :, cnt) > 0);
        z = ones(length(x), 1) * cnt;
        indices = [x y z]';
        if (~exist('coords'))
            coords = indices;
        else
            coords = [coords indices];
        end
    end
end

for cnt = 1:zdim
    if (mean(mean(scim2(:, :, cnt)) > 0))
        fprintf(1, '%d\n', cnt);
        [x, y] = find(scim2(:, :, cnt) > 0);
        z = ones(length(x), 1) * cnt;
        indices = [x y z];
        % remove identical points (likely contamination)
        common = intersect(coords', indices, 'rows');
        retainindices = 1:size(indices, 1);
        for pnt = 1:size(common, 1)
            for pnt2 = 1:size(indices, 1)
                if (mean(indices(pnt2, :) == common(pnt, :)) == 1)
                    retainindices = find(retainindices ~= pnt2);
                end
            end
        end
        indices = indices(retainindices, :);
        if (length(z) > length(retainindices))
            fprintf(1, 'removed %d overlapping pnts\n', length(z) - length(retainindices));
        end
        if (~exist('coords2'))
            coords2 = indices';
        else
            coords2 = [coords2 indices'];
        end
    end
end

fprintf(1, 'start distance measurement\n');
for loc = 1:length(coords)
    x = XStep * ImageParameters.decimatepts * (coords(1, loc) - coords2(1, :));
    y = YStep * ImageParameters.decimatepts * (coords(2, loc) - coords2(2, :));
    z = ZStep * (coords(3, loc) - coords2(3, :));
    dist = min(sqrt(x.^2 + y.^2 + z.^2));
    if (loc == 1)
        distances = dist;
    else
        distances = [distances dist];
    end
    if (rem(loc, 1000) == 0)
        fprintf(1, '\t%d (%d)\n', loc, length(coords));
        pause(0.1);
    end    
end

figure(2);
[dist, distx] = hist(distances, 100);
plot(distx, dist);

ImageParameters.NNDistances = distances;
CellParameters.ImageParameters = ImageParameters;



%%

% fit images with 2-D gaussians
Threshold = 90;

pixels2 = NoSomaImage;
indices = find(NoSomaImage < Threshold);
pixels2(indices) = 0;
indices = find(NoSomaImage >= Threshold);
pixels2(indices) = 1;

figure(1);
set(1, 'Position', [1 scrsz(4)/2 size(NoSomaImage, 2) size(NoSomaImage, 2)]);
imagesc(NoSomaImage);
hold on
axis tight

clear coords coords2;
indices = find(pixels2 > 0);

coords(:, 1) = floor(indices/length(pixels2));
coords(:, 2) = rem(indices, length(pixels2));

%ellipse_t = fit_ellipse(coords(:, 1), coords(:, 2), 1);

[u,covar,t,iter] = fit_mix_2D_gaussian(coords, 1)

%%
pixels2 = NoSomaImage2;
indices = find(NoSomaImage2 < Threshold);
pixels2(indices) = 0;
indices = find(NoSomaImage2 >= Threshold);
pixels2(indices) = 1;

figure(2);
set(2, 'Position', [scrsz(3)/2 scrsz(4)/2 size(NoSomaImage, 2) size(NoSomaImage, 2)]);
imagesc(NoSomaImage2);
hold on
axis tight

clear coords coords2;
indices = find(pixels2 > 0);

coords(:, 1) = floor(indices/length(pixels2));
coords(:, 2) = rem(indices, length(pixels2));

%ellipse_t = fit_ellipse(coords(:, 1), coords(:, 2), 1);

[u2,covar2,t2,iter2] = fit_mix_2D_gaussian(coords, 1)

%%
% overlap
[x, y] = meshgrid(1:length(NoSomaImage), 1:length(NoSomaImage));

df1 = x;
coords = [x(:) y(:)];

df1(:) = mvnpdf(coords, u', covar);
df1(:) = df1(:) / max(df1(:));

df2 = x;

df2(:) = mvnpdf(coords, u2', covar2);
df2(:) = df2(:) / max(df2(:));

overlap = sum(df1(:) .* df2(:)) / sum(df2(:) .* df2(:))


