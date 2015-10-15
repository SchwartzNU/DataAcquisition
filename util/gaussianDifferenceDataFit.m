function V = gaussianDifferenceDataFit(beta, x, y, y_err)
%beta 
%1 sd 1
%2 scale 2
%3 sd 2
%not using %4 offset (in X)
%4 offset parameter of sigmoid 
%5 slope parameter of sigmoid 

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
    G1sum = 1 .* (normcdf(x(i)/2, 0, beta(1)) - normcdf(-x(i)/2, 0, beta(1)));    
    %sigmoid = exp(beta(4).*exp(beta(5).*x(i)));
    %G1sum = G1sum.^beta(4);
    G2sum = beta(2) .* (normcdf(x(i)/2, 0, beta(3)) - normcdf(-x(i)/2, 0, beta(3)));
    fit(i) = G1sum-G2sum;
end

y_err= 1./y_err;
y_err = y_err./sum(y_err);

%V = sum(((fit-y).^2).*y_err);
V = sum((fit-y).^2);

%fit
%keyboard;
