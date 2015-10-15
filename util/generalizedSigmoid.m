function y = generalizedSigmoid(x,A,K,B,v,Q,M)
y = A + (K-A)./(1+Q.*exp(-B.*(x-M))).^1/v;