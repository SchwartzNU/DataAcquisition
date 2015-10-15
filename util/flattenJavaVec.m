function V = flattenJavaVec(jV)

V = [];
for i=1:jV.length
    V = [V; jV(i)];
end
