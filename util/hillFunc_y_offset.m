function y = hillFunc_y_offset(coeffs,x,w)
Kd = coeffs(1);
n = coeffs(2);
offset = coeffs(3);

if Kd<0, Kd = 0; end
if n<eps, n = eps; end

y = offset+x.^n./(Kd.^n + x.^n);
y = y./max(y);
y = y.*w;