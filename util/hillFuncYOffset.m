function y = hillFuncYOffset(x,Kd,n)
y = x.^n./(Kd.^n + x.^n);
offset = 0.5.^n./(Kd.^n + 0.5.^n);
y = y-offset;
y = y./max(y); %should I be doing this?