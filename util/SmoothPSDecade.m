function NewPowerSpec = SmoothPSDecade(PowerSpec, Freq, PtsPerDecade,varargin)
%function NewPowerSpec = SmoothPSDecade_Omit(PowerSpec,Freq, PtsPerDecade)
%or 
%function NewPowerSpec = SmoothPSDecade_Omit(PowerSpec,Freq, PtsPerDecade,OmitFreqs)
% This function takes a power spectrum and smooths it such that there are
% equal number of points in each decade set by PtsPerDecade. Routine computes
% average and sd of points and mean frequency for the averaged points.  Returns
% structure with four fields: average power spectrum values, sd,
% frequency of new samples and sd. 
% Possibility of Omitting some points in routine (60Hz and harmonics for example).
% Created: Angueyra Dec_2011

if isempty(PtsPerDecade)
    PtsPerDecade=20;
end

if ~isempty(varargin)
    OmitFreqs=varargin{1};
    NumOmitPts=length(OmitFreqs);
    % Find the indices of the wanted omitted frequencies in Freq
    k=0;
    Accuracy=10;
    OmitInd = [];
    for i=1:NumOmitPts
        if ~isempty(find(round(Freq*Accuracy)/Accuracy==OmitFreqs(i), 1))
            k=k+1;
            OmitInd(k)=find(round(Freq*Accuracy)/Accuracy==OmitFreqs(i),1);
        end
    end
    P=PowerSpec;
    F=Freq;
    % remove points to be omitted
    PowerSpec=PowerSpec(~ismember(Freq,Freq(OmitInd)));
    Freq=Freq(~ismember(Freq,Freq(OmitInd)));
end
LowestDecade=floor(log10(min(Freq(Freq>0))));
HighestDecade=ceil(log10(max(Freq)));
Decades=LowestDecade:1:HighestDecade;
NumDecades=size(Decades,2)-1;
% split PowerSpec into Decades after getting Freq indices
decadeFreqLimits=zeros(1,NumDecades+1);
for i=1:size(decadeFreqLimits,2)-1
    decadeFreqLimits(i)=find(Freq>=10^Decades(i),1,'first');
end
decadeFreqLimits(end)=find(Freq==max(Freq));
for i=1:NumDecades
    decadePS{i}=PowerSpec(decadeFreqLimits(i):decadeFreqLimits(i+1)-1);
    decadeFreq{i}=Freq(decadeFreqLimits(i):decadeFreqLimits(i+1)-1);
    % create equally spaced intervals for each decade
    decSpace{i}=logspace(Decades(i),Decades(i+1),PtsPerDecade+1);
end
for i=1:NumDecades
    if size(decadePS{i},2)<=PtsPerDecade %less points than PtsPerDecade in this decade
        decPts(i)=size(decadePS{i},2);
        SmoothdecadePS{i}=decadePS{i};
        SmoothdecadeFreq{i}=decadeFreq{i};
        SmoothdecadePS_SD{i}=zeros(size(decadePS{i}));
        SmoothdecadeFreq_SD{i}=zeros(size(decadePS{i}));
    else
        % find the points that belong to each interval
        for j=1:PtsPerDecade
            decFreqIndices{i}{j}=find(decadeFreq{i}>=decSpace{i}(j)&decadeFreq{i}<decSpace{i}(j+1));
        end
        % remove any empty intervals
        decFreqIndices{i}(cellfun('isempty',decFreqIndices{i}))=[];
        for j=1:size(decFreqIndices{i},2)
            SmoothdecadePS{i}(j)=mean(decadePS{i}(decFreqIndices{i}{j}));
            SmoothdecadePS_SD{i}(j)=std(decadePS{i}(decFreqIndices{i}{j}));
            SmoothdecadeFreq{i}(j)=mean(decadeFreq{i}(decFreqIndices{i}{j}));
            SmoothdecadeFreq_SD{i}(j)=std(decadeFreq{i}(decFreqIndices{i}{j}));
        end 
    end
end
NewPowerSpec.PowerSpec=[];
NewPowerSpec.sdPowerSpec=[];
NewPowerSpec.Freq=[];
NewPowerSpec.sdFreq=[];
for i=1:NumDecades
    NewPowerSpec.PowerSpec=horzcat(NewPowerSpec.PowerSpec,SmoothdecadePS{i});
    NewPowerSpec.sdPowerSpec=horzcat(NewPowerSpec.sdPowerSpec,SmoothdecadePS_SD{i});
    NewPowerSpec.Freq=horzcat(NewPowerSpec.Freq,SmoothdecadeFreq{i});
    NewPowerSpec.sdFreq=horzcat(NewPowerSpec.sdFreq,SmoothdecadeFreq_SD{i});
end

end
