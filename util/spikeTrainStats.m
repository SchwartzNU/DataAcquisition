function returnStruct = spikeTrainStats(sp, prepts, stimpts, Stats)
%returnStruct = currentTraceStats(dataM, SampleInterval)

L = length(sp);
for i=1:L
    sp_sitmInterval{i} = sp{i}(sp{i}>prepts & sp{i}<=prepts+stimpts);
    sp_baseline{i} = sp{i}(sp{i}<prepts);
    spikeCount(i) = length(sp_sitmInterval{i});
end

if strmatch('spikeCount_byEpoch', Stats) %not baselineSubtracted
    returnStruct.spikeCount_byEpoch = spikeCount;
end

if strmatch('spikeCount_mean', Stats)
    returnStruct.spikeCount_mean = mean(spikeCount);
end

if strmatch('spikeCount_sd', Stats)
    returnStruct.spikeCount_sd = std(spikeCount);
end