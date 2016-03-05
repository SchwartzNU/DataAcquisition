function positions = generatePositions(mode, settings)


if strcmp(mode, 'radial')

    numAngles = settings(1);
    numRadii = settings(2);
    fullRadius = settings(3);


    % angles = freqspace(numAngles, 'whole') * pi;
    % radii = linspace(1/numRadii,1, numRadii) * fullRadius;
    radii = logspace(-1, 0, numRadii) * fullRadius - fullRadius/numRadii;

    numPos = numAngles * numRadii;
    % positions = zeros(numPos,2);
    positions = [];

    p = 1; % include 0,0 as first point

    for ri = 1:numRadii
        rad = radii(ri);

        if ri == 1
            na = 1;
        elseif ri < numRadii / 2
            na = numAngles / 2;
        else
            na = numAngles;
        end

        angles = freqspace(na, 'whole') * pi;

        for ai = 1:na
            ang = angles(ai);

            positions(p,:) = rad * [cos(ang); sin(ang)];
            p = p + 1;
        end
    end

    % plot(positions(:,1), positions(:,2), 'o')
    % axis equal
    
elseif strcmp(mode, 'grid')
    searchRadius = settings(1);
    countPerDim = settings(2);
    
    posList = linspace(-.5, .5, countPerDim) * searchRadius;
    p = 1;
    positions = [];
    for a = posList
        for b = posList
            positions(p,:) = [a;b];
            p = p + 1;
        end
    end
    
elseif strcmp(mode, 'random')
    numSpots = settings(1);
    exclusionDistance = settings(2);
    searchRadius = settings(3);
    
    positions = zeros(numSpots, 2);
    
    for si = 2:numSpots % let first be [0,0]
        minDistToOtherSpot = 0; % the minimum space between this and all other spots
        haltCounter = 0; % don't keep trying forever if input is too difficult
        while (minDistToOtherSpot < exclusionDistance || distFromCenter > searchRadius) && haltCounter < 100
            pos = searchRadius / 2 * randn(1, 2);
            distFromCenter = sqrt(sum(pos.^2));
            minDistToOtherSpot = Inf;
            for os = 1:si
                minDistToOtherSpot = min(minDistToOtherSpot, sqrt(sum((pos - positions(os,:)).^2)));
            end
            haltCounter = haltCounter + 1;
        end
        positions(si,:) = pos;
    end
elseif strcmp(mode, 'triangular')
    searchRadius = settings(1);
    spotSpacing = settings(2);

    minSideLen = sqrt(3) * searchRadius * 2;
    n = ceil(minSideLen / spotSpacing);
    sidelen = n * spotSpacing;

    center = [0 0];

    tcorner = [-sidelen / 2, 0;
               0, sidelen * sqrt(3)/2;
               sidelen / 2, 0];
    tcorner = bsxfun(@plus, tcorner, -1*[0, sidelen * sqrt(3)/6]);
    tcorner = bsxfun(@plus, tcorner, center);

    positions = [];
    point_index = 0;

    for i = 0 : n
        for j = 0 : n - i
            k = n - i - j;
            pos = ( i * tcorner(1,:) + j * tcorner(2,:) + k * tcorner(3,:) ) / n;
            distFromCenter = sqrt(sum((pos - center).^2));
            if distFromCenter <= searchRadius
                point_index = point_index + 1;
                positions(point_index, 1:2) = pos;
            end
        end
    end
    
    % add spacing to avoid adjacent successive spots 
    order = (1:2:length(positions))';
    order = vertcat(order, order + 1);
    order = order(1:length(positions));
    positions = positions(order, :);    
    
end
    