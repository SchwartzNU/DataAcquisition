function distances = NNdistance(scim,scim2)

ImageParameters.decimatepts = 1;
%microns per pixel
XStep = 0.4144;
YStep = 0.4144;

if (mean(mean(scim(:, :)) > 0))
    [x, y] = find(scim(:, :) > 0);
    indices = [x y]';
    coords = indices;
end

if (mean(mean(scim2(:, :)) > 0))
    [x, y] = find(scim2(:, :) > 0);
    indices = [x y];
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
    
    coords2 = indices';    
end


fprintf(1, 'start distance measurement\n');
for loc = 1:length(coords)
    x = XStep * ImageParameters.decimatepts * (coords(1, loc) - coords2(1, :));
    y = YStep * ImageParameters.decimatepts * (coords(2, loc) - coords2(2, :));
    dist = min(sqrt(x.^2 + y.^2));
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
[dist, distx] = hist(distances, 40);
plot(distx, dist);

ImageParameters.NNDistances = distances;
CellParameters.ImageParameters = ImageParameters;