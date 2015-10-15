% Determines whether a .NET generic enumerable sequence contains any elements.

function c = enumerableToCellArray(e, type)
    l = NET.invokeGenericMethod('System.Linq.Enumerable', 'ToList', {type}, e);
    
    c = cell(1, l.Count);
    for i=1:l.Count
        c{i} = l.Item(i-1);
    end
end