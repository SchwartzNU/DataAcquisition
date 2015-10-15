function [centerY,widthX,centerX,widthY,theta,Z,error] = fitRFNew(RF)
[a b]=size(RF);
N=a*b;
Z = [];

[I J]=ind2sub([a b],(1:N)');
X=cat(2,I,J);
y=reshape(RF,N,1);
beta0=[0 1 .2 .2 0.2 40 40]';
[xmax,ymax, mx] = maxMat(RF);
beta0(2)=mx;
beta0(6)=xmax;
beta0(7)=ymax;

[beta,n,n,n,error] = nlinfit(X,y,@gauss2D,beta0);

error
centerX = beta(6);
centerY = beta(7);
a = beta(3); b = beta(4); c = beta(5);
%M = [a b; b c];
%[eigVec, eigVal] = eig(M)
%pause;
%W = 1./eigVal;
%widthX = sqrt(W(1,1));
%widthY = sqrt(W(2,2));
%theta = asin(eigVec(1,2));

widthX = 2^(1/2)*((a+c+(-2*c*a+b^2+a^2+c^2)^(1/2))/(4*c*a-b^2))^(1/2)
widthY = 1/(4*c*a-b^2)*2^(1/2)*((4*c*a-b^2)*(a+c-(-2*c*a+b^2+a^2+c^2)^(1/2)))^(1/2)
theta = acos(((a*widthY^2-c*widthX^2)*widthX^2*widthY^2)/(widthY^4 - widthX^4)) - pi/2;


% D = zeros(78^2,2);
% for i=1:78
%     for j=1:78
%         D((i-1)*78+j,1) = i;
%         D((i-1)*78+j,2) = j;
%     end
% end
% 
% Z = gauss2D(beta,D);


function [x,y, mx] = maxMat(A)
% computes x and y indices and value of maximum value of matrix

[C,I]=max(A);
[mx,y]=max(C);
x = I(y);