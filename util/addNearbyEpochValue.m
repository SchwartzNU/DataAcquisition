function addNearbyEpochValue(epochList)
L = epochList.length;
startTimes = zeros(1,L);
V = zeros(1,L);
epochNums = zeros(1,L);
for i=1:L
    curEpoch = epochList.valueByIndex(i);
    startTimes(i) = datenum(curEpoch.startDate');
    
    %translationdistance
    tx = curEpoch.get('protocolSettings').get('stimuli:Amp_1:translationX');
    ty = curEpoch.get('protocolSettings').get('stimuli:Amp_1:translationY');
    V(i) = round(sqrt(tx^2+ty^2));    
    epochNums(i) = curEpoch.get('protocolSettings').get('acquirino:epochNumber');
end
[startTimes, Ind] = sort(startTimes);
V = V(Ind); 
epochNums = epochNums(Ind);
%keyboard;

%add value from nearest epoch
for i=1:L
    curEpoch = epochList.valueByIndex(Ind(i));
    if i==1
        nearInd = 2;
    elseif i==L
        nearInd = L-1;
    else
       preTimeDiff = abs(startTimes(i-1) - startTimes(i))*1000;
       postTimeDiff = abs(startTimes(i+1) - startTimes(i))*1000;
%       pause
       if preTimeDiff < postTimeDiff
          nearInd = i-1;
       else
          nearInd = i+1;
       end
    end   
    disp(['user:nearbyTranslationSize ==  ' num2str(V(nearInd))]);  
    %epochNums(i)
    %epochNums(nearInd)
    %pause;
    curEpoch.protocolSettings.put('user:nearbyTranslationSize', V(nearInd));
end
