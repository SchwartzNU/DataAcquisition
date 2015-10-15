function [] = getBinMeans(node,resultField,bins)

R = node.custom.get('results');
%Rstar = R.get('Rstar');
Rstar_java = R.get('splitOnSettingepoch_user_background_Rstar');


%make into matlab array
Rstar = zeros(1,Rstar_java.length);
for i=1:Rstar_java.length
    Rstar(i) = Rstar_java(i);
end

if R.containsKey([resultField '_Amp_1']) && R.containsKey([resultField '_Amp_2'])
    %combine amps
    V1 = R.get([resultField '_Amp_1']);
    V2 = R.get([resultField '_Amp_2']);
    
    V = zeros(1, length(V1));
    for i=1:length(V1)
        if isempty(V1(i)) && isempty(V2(i))
            V(i) = nan;
        elseif isempty(V1(i))
            V(i) = V2(i);
        else
            V(i) = V1(i);
        end
    end
else
    Vjava = R.get(resultField);
    V = zeros(1,length(Vjava));
    for i=1:length(Vjava)
        if isempty(Vjava(i))
            V(i) = nan;
        else
            V(i) = Vjava(i);
        end
    end
end

L = size(bins,1);

Rstar_mean = zeros(1,L);
Rstar_err = zeros(1,L);
V_mean = zeros(1,L);
V_err = zeros(1,L);

for i=1:L
    ind = Rstar >= bins(i,1) & Rstar < bins(i,2);
    N = sum(ind);
    Rstar_mean(i) = nanmean(Rstar(ind));
    Rstar_err(i) = nanstd(Rstar(ind))./sqrt(N);
    V_mean(i) = nanmean(V(ind));
    V_err(i) = nanstd(V(ind))./sqrt(N);
end

R.put('Rstar_mean',Rstar_mean);
R.put('Rstar_err',Rstar_err);
R.put([resultField '_binMeans'],V_mean);
R.put([resultField '_binErrs'],V_err);