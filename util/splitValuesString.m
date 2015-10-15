function S = splitValuesString(node)
V = node.splitValues.values;
S = num2str(V{1});
for i=2:length(V)
    S = [S '_' num2str(V{i})];
end
