function M = makeUniformDist(M)
%C is contrast
M_flat = M(:);
bins = [-Inf prctile(M_flat,1:1:100)];
M_orig = M;
for i=1:length(bins)-1
    M(M_orig>bins(i) & M_orig<=bins(i+1)) = i*(1/(length(bins)-1));
end
 M = M - min(min(M)); %set mins to 0
 M = M./max(max(M)); %set max to 1;
 M = M - mean(mean(M)) + 0.5; %set mean to 0.5;