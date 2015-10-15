function z=gauss2D(beta,W)

if(size(beta,2)~=1 || size(W,2)~=2 || size(beta,1) ~=7)
   error('Bad arguments to gauss 2D');
end

L=size(W,1);
x=W(:,1);
y=W(:,2);
c1=beta(1,1);
c2=beta(2,1);
A=beta(3,1);
B=beta(4,1);
C=beta(5,1);
x0=beta(6,1);
y0=beta(7,1);
xx=x-x0;
yy=y-y0;

z=zeros(L,1);
for i=1:L
   if(-A*xx(i)^2 - B*xx(i)*yy(i) - C*yy(i)^2 > 50)
       z(i)=100;
   else
       z(i)=c1+c2*exp(-A*xx(i)^2 - B*xx(i)*yy(i)-C*yy(i)^2);
   end
end