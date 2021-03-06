function C = myCov(M)
%calculate covariance matrix:
%[var(x) cov(xy;
%cov(xy) var(y)];

C = [];
[r,c] = size(M);

for i=1:r
    vx(i) = (M(i,:) - mean(M(i,:)))*(M(i,:) - mean(M(i,:)))';
end
for i=1:c
    vy(i) = (M(:,i) - mean(M(:,i)))'*(M(:,i) - mean(M(:,i)));
end

varX = mean(vx)
varY = mean(vy)

%sumX = sum(M,2);
%sumY = sum(M,1);
%varX = mean(sumX.*sumX) - mean(sumX)*mean(sumX);
%varY = mean(sumY.*sumY) - mean(sumY)*mean(sumY);

R = corrcoef(M,M');
C(1,1) = varX;
C(2,2) = varY;
%these are the same
C(1,2) = R(1,2)*sqrt(varX*varY);
C(2,1) = R(2,1)*sqrt(varX*varY);


