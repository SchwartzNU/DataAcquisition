function [HR, FAR, HR_opt, FAR_opt, dprime_opt] = ROCanalysis(noise, signal)

Nsteps = 100;
HR = zeros(1,Nsteps);
FAR = zeros(1,Nsteps);

T = linspace(min([noise signal]),max([noise signal]),Nsteps);

noiseTrials = length(noise);
sigTrials = length(signal);

for i=1:Nsteps
   HR(i) = sum(signal>=T(i))./sigTrials;
   FAR(i) = sum(noise>=T(i))./noiseTrials;   
end

HR_temp = HR;
HR_temp(HR==0) = 0.01;
HR_temp(HR==1) = 0.99;
FAR_temp = FAR;
FAR_temp(FAR==0) = 0.01;
FAR_temp(FAR==1) = 0.99;


dprime = norminv(HR_temp) - norminv(FAR_temp);
[dprime_opt, ind] = max(dprime);
HR_opt = HR(ind);
FAR_opt = FAR(ind);
