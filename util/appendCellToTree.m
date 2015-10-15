function tree = appendCellToTree(tree, cellTree)
tree.children{end+1} = cellTree.children{1};
tree.leafNodes = [tree.leafNodes; cellTree.leafNodes];



