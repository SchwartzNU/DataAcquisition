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
    width = settings(1);
    countPerDim = settings(2);
    
    posList = linspace(-.5, .5, countPerDim) * width;
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
    width = settings(3);
    positions = zeros(numSpots, 2);
    
    for si = 2:numSpots
        d = 0;
        while d < exclusionDistance
            posPrev = positions(si-1,:);
            pos = width * (randn(1, 2));
            d = sqrt(sum((pos - posPrev).^2));
        end
        positions(si,:) = pos;
    end
end
    
    