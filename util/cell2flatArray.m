function V = cell2flatArray(C)
nCells = length(C);
V = [];
for i=1:nCells
   curCell = C{i};
   [r,c] = size(curCell);
   if c>1, curCell = cellCell'; end
   V = [V; curCell];
end


