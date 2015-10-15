function decimated = downsample2d(original, decimatepts)


if (decimatepts > 1)
    xpts = size(original, 1);
    ypts = size(original, 2);

    for x = 1:xpts
        temp(x, :) = downsample(original(x, :), decimatepts);
    end

    for y = 1:ceil(ypts/decimatepts)
        decimated(:, y) = downsample(temp(:, y), decimatepts);
    end

else
    decimated = original;
end
