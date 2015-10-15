function [pMed, kMed] = ksLinearityTest(pairR,linsum,minLen,type)
%type is 'smalller' or 'larger'

L = length(linsum);
I = randperm(L);
z=1;
for i=1:minLen:L-minLen+1
   linsumPart = linsum(I(i:i+minLen-1));
   [h,p(z),kstat(z)] = kstest2(pairR,linsumPart,.05,type);
   z=z+1;
end
pMed = median(p);
kMed = median(kstat);

