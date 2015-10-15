function nodes = getLevel(node,levelSplit,splitVal)
nodes = [];
if ~exist('splitVal','var')
    splitVal = [];
end

if ~node.splitValues.containsKey(levelSplit) %above correct level
    if ~isempty(node.children)
        for i=1:node.children.length %call on all children
            nodes = [nodes, getLevel(node.children.valueByIndex(i),levelSplit,splitVal)];
        end
    end
else %has split key
    if ~isempty(splitVal) && (~isequal(splitVal,node.splitValue))
        %did not match
    elseif node.custom.get('isSelected') %did match and selected        
        nodes = [nodes, node];
    end
end