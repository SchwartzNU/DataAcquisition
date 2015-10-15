function axisZoomCallback(hObject,eventData)
curH = hObject;
parent = get(curH,'parent');
while ~isempty(parent)
    curH = parent;
    parent = get(curH,'parent');
    if strcmp(get(curH,'type'),'figure'), break; end
end
clicktype = get(curH,'SelectionType');
if strcmp(clicktype,'open');
    xlim(hObject,'auto');
    ylim(hObject,'auto');
else
    point1 = get(hObject,'CurrentPoint');
    rbbox;
    point2 = get(hObject,'CurrentPoint');
    
    p1X = point1(1,1);
    p1Y = point1(1,2);
    p2X = point2(1,1);
    p2Y = point2(1,2);
    
    if p1X~=p2X && p1Y~=p2Y
        set(hObject','Xlim',[min(p1X,p2X) max(p1X,p2X)]);
        set(hObject','Ylim',[min(p1Y,p2Y) max(p1Y,p2Y)]);
    end
end