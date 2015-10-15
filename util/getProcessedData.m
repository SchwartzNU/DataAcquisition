function [Dmean, D, timeVec, baseline, errorBars] = getProcessedData(node, RespStreamName, lowPassFilter, baselineSubtract, baselineTime, errorBars)

%get pre_points
[prePoints, sammpleRate] = getPrePoints(node);

%get data
if ischar(RespStreamName)
    respChar = RespStreamName;
else
    respChar = RespStreamName.toCharArray;
end
dataM = riekesuite.getResponseMatrix(node.epochList, respChar);

%end
%filter
if ~isempty(lowPassFilter)
    dataM = LowPassFilter(dataM, lowPassFilter, 1./sammpleRate);
end

if isempty(baselineTime)
    baseline = mean(dataM(:,1:prePoints),2);
elseif prePoints == 0 %special case, no prepoints so look forward in time
    baselineTime_pts = round(baselineTime.*sammpleRate);
    baseline = mean(dataM(:,1:baselineTime_pts),2);
else
    baselineTime_pts = round(baselineTime.*sammpleRate);
    baseline = mean(dataM(:,prePoints-baselineTime_pts+1:prePoints),2);
end
if baselineSubtract
    dataM_baselineSubtracted = dataM - repmat(baseline,1,size(dataM,2));
    D = dataM_baselineSubtracted;
else
    D = dataM;
end

Dmean = mean(D,1);

timeVec = ((1:size(D,2))-prePoints)./sammpleRate; 

%error bars
if ~isempty(errorBars)
    if strcmp(errorBars, 'sem')
        errorBars = std(dataM_baselineSubtracted,1)./sqrt(size(dataM_baselineSubtracted,1));
    elseif strcmp(errorBars, 'sd')
        errorBars = std(dataM_baselineSubtracted,1);
    end
end

%flush
%node.epochList.flush();