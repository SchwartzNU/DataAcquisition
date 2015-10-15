function segments = traceCell(M)

h = image(M);
ax = gca;
%colormap(ax,'gray');
done = 0;
hold(ax,'on');
lineIndex = 0;
segments = cell(1,1);
while ~done    
    for i=1:lineIndex
        curSeg = segments{i};
        plot(curSeg(:,1),curSeg(:,2),'b');
    end
    [x,y] = getline;
    curLine = line(x,y,'color','r');
    set(curLine,'visible','on');
    isValid = 0;
    while ~isValid
        resp = input('Accept [a] / Delete [d] / Finished [q]: ', 's');
        if strcmp(resp,'q');
            isValid = 1;
            done = 1;
            return;
        elseif strcmp(resp,'a');
            lineIndex = lineIndex + 1;
            segments{lineIndex} = [x, y];
            isValid = 1;
        elseif strcmp(resp,'d');
            isValid = 1;
        end
    end    
    set(curLine,'visible','off');
end
hold(ax,'off');
