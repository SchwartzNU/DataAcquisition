function V = flattenVectorOfObjectVectors(VV)

V = [];
for i=1:length(VV)
    if strfind(class(VV(i)),'java.lang.Object[]')
        V = [V; javaVecToMatlab(VV(i))'];
    elseif iscell(VV(i))
        V = [V; flattenCellArray(VV(i))];
    end
        
end
