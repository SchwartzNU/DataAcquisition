function im = getSquareImageRegion(im)
image(im);
k = waitforbuttonpress;
point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   % return figure units
point2 = get(gca,'CurrentPoint');    % button up detected
point1 = point1(1,1:2);              % extract x and y
point2 = point2(1,1:2);
p1 = min(point1,point2);             % calculate locations
offset = abs(point1-point2);         % and dimensions

offset = min(offset);

%x = [p1(1) p1(1)+offset(1) p1(1)+offset(1) p1(1) p1(1)]
%y = [p1(2) p1(2) p1(2)+offset(2) p1(2)+offset(2) p1(2)]
%keyboard;
%minLen = min(offset);

coords = round([p1(1) p1(1)+offset p1(2) p1(2)+offset]);
im = im(coords(3):coords(4), coords(1):coords(2),:);
image(im);
