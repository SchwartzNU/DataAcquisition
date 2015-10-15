function [] = addGammaTables(tree,letters,tables)

cellNodes = getLevel(tree,'protocolSettings.acquirino:cellBasename'); %checks for isSelected

for i=1:length(cellNodes)
    results = struct;
    for j=1:length(letters)
        if strfind(cellNodes(i).splitValue,letters{j})
            results.gamma = tables{j};
            cellNodes(i).custom.put('results',riekesuite.util.toJavaMap(results));
        end
    end
end
