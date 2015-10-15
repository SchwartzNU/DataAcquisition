function y = hillFunc(x,Kd,n)
y = x.^n./(Kd.^n + x.^n);