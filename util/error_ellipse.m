function [h, A] = error_ellipse(C)
%C is covariance matrix

eVals = eigs(C);
theta = 0.5*atan(2*C(1,2)/(C(1,1)-C(2,2)));

if C(1,1) > C(2,2) %x variance larger
   ra = sqrt(max(eVals)); 
   rb = sqrt(min(eVals));
else
   ra = sqrt(min(eVals)); 
   rb = sqrt(max(eVals));
end

h = ellipse(ra,rb,theta,0,0);
A = pi*ra/2*rb/2;

