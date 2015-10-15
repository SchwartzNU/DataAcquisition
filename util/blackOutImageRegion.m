function im = blackOutImageRegion(im)
if ndims(im) == 3
    image(im);
else
    imagesc(im);
end
k = waitforbuttonpress;
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1,1:2);              % extract x and y
point2 = point2(1,1:2);
p1 = min(point1,point2);             % calculate locations
offset = abs(point1-point2);         % and dimensions

%x = [p1(1) p1(1)+offset(1) p1(1)+offset(1) p1(1) p1(1)]
%y = [p1(2) p1(2) p1(2)+offset(2) p1(2)+offset(2) p1(2)]
%keyboard;
minLen = min(offset);

coords = round([p1(1) p1(1)+minLen p1(2) p1(2)+minLen]);
if ndims(im) == 3
    im(coords(3):coords(4), coords(1):coords(2),:) = 0;
else
     im(coords(3):coords(4), coords(1):coords(2)) = 0;
end
if ndims(im) == 3
    image(im);
else
    imagesc(im);
end