function V = getUpTreeParam(node,paramName)
parent = node.parent;
paramFound = 0;
while ~isempty(parent)
    M = makeNodeSearchMap(parent);
    if M.isKey(paramName)
        V = M(paramName);
        paramFound = 1;
        break;
    end
    parent = parent.parent;    
end
if ~paramFound
    error(['Parameter ' paramName ' not found']);
end
