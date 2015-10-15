function P = allPairs(x,y)
Lx = length(x);
Ly = length(y);

P = zeros(Lx*Ly,2);
z = 1;
for i=1:Lx
    for j=1:Ly
        P(z,:) = [x(i), y(j)];
        z=z+1;
    end
end