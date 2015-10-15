function I = mutualInformation_old(M, Ps)
%M is the follwingMatrix
%entries are P(r|s)
%rows are different responses
%colums are different stimuli
%
%Ps is a vector of the probability of each stimulus
%
%

M = M./sum(sum(M))

[Nr, Ns] = size(M);

Ps_given_r = zeros(Nr,Ns);
Pr_given_s = zeros(Nr,Ns);



%normalize for each stim
for i=1:Ns
    if sum(M(:,i)) == 0
        Pr_given_s(:,i) = M(:,i)*0;
    else
        Pr_given_s(:,i) = M(:,i)./sum(M(:,i));
    end
end

Pr = sum(M,2);
Pr = Pr./sum(Pr)

I = 0;

%entropy of P(s)
for s=1:Ns
    I = I-Ps(s)*mylog2(Ps(s));
end

%Pr = Pr
%minus entropy of P(s|r)

Pr_given_s(Pr_given_s==0) = eps;
Pr_given_s
for s=1:Ns
    for r=1:Nr
        Ps_given_r(r,s) = Pr_given_s(r,s)*Ps(s)/Pr(r);
    end
    Ps_given_r(r,:) = Ps_given_r(r,:)./sum(Ps_given_r(r,:));
end

Ps_given_r(Ps_given_r==0) = eps;
Ps_given_r

for s=1:Ns
    for r=1:Nr
        I = I + M(r,s)*mylog2(Ps_given_r(r,s));
    end
end

if isnan(I)
    keyboard
end







