function V = flattenCellArray(C,recursive)

V = [];
for i=1:length(C)
    curElement = C{i};
    if exist('recursive','var')
        while iscell(curElement)
            curElement = flattenCellArray(curElement);
        end
    end
    V = [V; curElement];
end
