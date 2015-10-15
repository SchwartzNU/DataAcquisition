function [X,Y] = getBox()
done = 0;
while ~done
    k = waitforbuttonpress;
    point1 = get(gca,'CurrentPoint');
    rbbox;
    point2 = get(gca,'CurrentPoint');
    
    p1X = point1(1,1);
    p1Y = point1(1,2);
    p2X = point2(1,1);
    p2Y = point2(1,2);
    
    if p1X~=p2X && p1Y~=p2Y
        done = 1;
        X = [min(p1X,p2X), max(p1X,p2X)];
        Y = [min(p1Y,p2Y), max(p1Y,p2Y)];
        return;
    end
end