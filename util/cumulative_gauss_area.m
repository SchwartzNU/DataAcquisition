function [fit] = cumulative_gauss_area(beta, x)

fit = zeros(size(x));
for i=1:length(x)
    p = normcdf([-x(i) x(i)], 0, abs(beta(1)));
    fit(i) = p(2) - p(1);
end
