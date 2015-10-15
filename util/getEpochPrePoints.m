function [prePoints, sampleRate] = getEpochPrePoints(epoch)
stimStreams = epoch.stimuli;
s = stimStreams(1).toString.toCharArray;
stimObj = epoch.stimuli.get(s(2:end-2));

if length(stimStreams) > 1
    disp('Warning: multiple stim streams, getting prepts from first one');
end

sampleRate = double(stimObj.sampleRate);

if (strcmp(epoch.protocolSettings.get('notes:protocolName'), 'LED Adaptation Kinetics using Blue LED') || ...
        strcmp(epoch.protocolSettings.get('notes:protocolName'), 'LED Adaptation Kinetics using Green LED'))
    prePoints = epoch.protocolSettings.get('notes:Pre'); %special case for this stim
    %    prePoints = 0;
elseif (strcmp(epoch.protocolSettings.get('notes:protocolName'), 'LED Contrast Adapt + Pulse using Blue LED') || ...
        strcmp(epoch.protocolSettings.get('notes:protocolName'), 'LED Contrast Adapt + Pulse using Green LED'))
    prePoints = 0;
elseif (strcmp(epoch.protocolSettings.get('notes:protocolName'), 'LED Paired Pulse using Blue LED') || ...
        strcmp(epoch.protocolSettings.get('notes:protocolName'), 'LED Paired Pulse using Greeg LED'))
    prePoints = epoch.protocolSettings.get('notes:Pre');
elseif strcmp(epoch.protocolSettings.get('stimuli:Amp_1:stimClass'), 'StripsAdaptationStimulus')
    prePoints = round(stimObj.get('parameters').get('flashStartFrame')./60.*sampleRate);
elseif ~isempty(stimObj.get('parameters')) && ~isempty(stimObj.get('parameters').get('spatial_prepts'))
    %prepts for spatial, assumes exactly 60Hz which may be significantly
    %off for long stimuli.
    prePoints = round(stimObj.get('parameters').get('spatial_prepts')./60.*sampleRate);
else %non-spatial stim
    prePoints = stimObj.get('parameters').get('prepts');
end
