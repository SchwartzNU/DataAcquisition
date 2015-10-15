function tree = concatenateTrees(treeA, treeB)

tree = treeA;
for i=1:length(treeB.children)
    tree.children{end+1} = treeB.children{i};
    
end
tree.leafNodes = [tree.leafNodes; treeB.leafNodes];