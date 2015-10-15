function fit = gaussianDifferenceSurroundOnly(beta, x)
%beta 
%1 sd 1
%2 scale 2
%3 sd 2
%4 offset (in X)

%can't have negative s.d
%if beta(2)<=0
%    beta(2) = eps;
%end
%if beta(4)<=0
%    beta(4) = eps;
%end



x = x - beta(4);

beta(1) = abs(beta(1));
beta(3) = abs(beta(3));
%beta(3) = 500;

fit = zeros(length(x),1);
for i=1:length(x)
    G1sum = 0;
    G2sum = beta(2) .* (normcdf(x(i)/2, 0, beta(3)) - normcdf(-x(i)/2, 0, beta(3)));
    fit(i) = G1sum-G2sum;
end