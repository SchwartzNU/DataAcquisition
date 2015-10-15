function Xnew = resample2d(X,a,b)
%resamples each column

[r,c] = size(X);
Xnew = zeros(r*a/b,c);
for i = 1:c
    Xnew(:,i) = resample(X(:,i),a,b);
end