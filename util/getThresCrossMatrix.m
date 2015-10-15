function Ind = getThresCrossMatrix(M,th,dir)
%run getThresCross on rows
L = size(M,1); 
Ind = cell(L,1);
for i=1:L
    Ind{i} = getThresCross(M(i,:),th,dir);
end
