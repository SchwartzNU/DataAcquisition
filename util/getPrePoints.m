function [prePoints, sampleRate] = getPrePoints(node)
el = node.epochList;
sampleEpoch = el.firstValue;
stimStreams = el.stimuliStreamNames;

if length(stimStreams) > 1
    disp('Warning: multiple stim streams, getting prepts from first one');
end

stimObj = sampleEpoch.stimuli.get(stimStreams(1));
sampleRate = double(stimObj.sampleRate);

if (strcmp(sampleEpoch.protocolSettings.get('notes:protocolName'), 'LED Adaptation Kinetics using Blue LED') || ...
    strcmp(sampleEpoch.protocolSettings.get('notes:protocolName'), 'LED Adaptation Kinetics using Green LED'))
    prePoints = sampleEpoch.protocolSettings.get('notes:Pre'); %special case for this stim
%    prePoints = 0;
elseif (strcmp(sampleEpoch.protocolSettings.get('notes:protocolName'), 'LED Contrast Adapt + Pulse using Blue LED') || ...
    strcmp(sampleEpoch.protocolSettings.get('notes:protocolName'), 'LED Contrast Adapt + Pulse using Green LED'))
    prePoints = 0;
elseif (strcmp(sampleEpoch.protocolSettings.get('notes:protocolName'), 'LED Paired Pulse using Blue LED') || ...
    strcmp(sampleEpoch.protocolSettings.get('notes:protocolName'), 'LED Paired Pulse using Greeg LED'))
    prePoints = sampleEpoch.protocolSettings.get('notes:Pre');
elseif strcmp(sampleEpoch.protocolSettings.get('stimuli:Amp_1:stimClass'), 'StripsAdaptationStimulus')
    prePoints = round(stimObj.get('parameters').get('flashStartFrame')./60.*sampleRate);    
elseif ~isempty(stimObj.get('parameters')) && ~isempty(stimObj.get('parameters').get('spatial_prepts'))
    %prepts for spatial, assumes exactly 60Hz which may be significantly
    %off for long stimuli.
    prePoints = round(stimObj.get('parameters').get('spatial_prepts')./60.*sampleRate);
else %non-spatial stim
    prePoints = stimObj.get('parameters').get('prepts');
end


