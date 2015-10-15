function [D_mean_derived, D_derived, beta] = subtractScaledIntervalResp(D,Dmean_sis,ind)
Ntrials = size(D,1);

curResp_part = mean(D(:,ind),1);
template_part = Dmean_sis(ind);

beta = nlinfit(template_part,curResp_part,@linethrough0,1);
resp_pred = linethrough0(beta,Dmean_sis);
D_mean_derived = mean(D,1) - resp_pred;
D_derived = D - repmat(resp_pred,Ntrials,1);



