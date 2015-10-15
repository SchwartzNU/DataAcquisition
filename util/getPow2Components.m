function set = getPow2Components(n)

%add one to powers of two so we start with index 1 instead of zero
set = [];
next = nextpow2(n);
if (2^next == n), set = next+1; return; %one component
else
    while n > 0        
        if n==2^next 
            n = n-2^next;
            set = [set next+1];
        else
            n = n-2^(next-1); 
            set = [set next];
        end
        next = nextpow2(n); 
    end
end