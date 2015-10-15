function [fit, centerFit, surroundFit] = gaussianDifference(beta, x)
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
centerFit = zeros(length(x),1);
surroundFit = zeros(length(x),1);

for i=1:length(x)
    G1sum = 1 .* (normcdf(x(i)/2, 0, beta(1)) - normcdf(-x(i)/2, 0, beta(1)));    
    %sigmoid = exp(beta(4).*exp(beta(5).*x(i)));
    %G1sum = G1sum.^beta(4);
    centerFit(i) = G1sum;
    G2sum = beta(2) .* (normcdf(x(i)/2, 0, beta(3)) - normcdf(-x(i)/2, 0, beta(3)));
    surroundFit(i) = G2sum;
    fit(i) = G1sum-G2sum;
end


%fit
%keyboard;
