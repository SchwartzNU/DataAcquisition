function D = ndiff(V,n)

D = zeros(1,length(V)-n);
for i=1:length(V)-n
   D(i) = V(i+n) - V(i); 
end

%like diff, but spaced by n