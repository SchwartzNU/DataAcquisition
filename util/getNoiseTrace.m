function S = getNoiseTrace(epoch)
nDivisions = epoch.protocolSettings.get('stimuli:Amp_1:nDivisions');
randSeed = epoch.protocolSettings.get('stimuli:Amp_1:randSeed');
frameDwell = epoch.protocolSettings.get('stimuli:Amp_1:frameDwell');
spatial_stimpts = epoch.protocolSettings.get('stimuli:Amp_1:spatial_stimpts');
stimStd = epoch.protocolSettings.get('stimuli:Amp_1:stimStd');
sampleRate = epoch.stimuli.get('Amp_1').get('sampleRate');
%SampleInterval = 1./sampleRate;
%prepts for spatial, assumes exactly 60Hz which may be significantly
%off for long stimuli.


frameMonitorData = riekesuite.getResponseVector(epoch,'Frame_Monitor');

frameMonitorData = frameMonitorData./max(frameMonitorData);
frameMonitorData = LowPassFilter(frameMonitorData,20,1E-4);

stimIntervals = getThresCross(frameMonitorData,0.5,1);
periods = diff(stimIntervals);

meanPeriod = mean(periods(2:end));
pointsPerStimPt = meanPeriod/sampleRate; %use this to rescale stim a bit at end, should be near 1

stimPoints = round(pointsPerStimPt*spatial_stimpts./60.*sampleRate);
stimPoints_collected = round(spatial_stimpts./60.*sampleRate);

randn('seed', randSeed);
% noise waveform
wavePnts = ceil(spatial_stimpts./frameDwell);
wave = normrnd(0,stimStd,1,wavePnts); % ignores discretization, but this is probably fine 
levels = linspace(-1,1,nDivisions);

for i=1:wavePnts
    [minVal,loc] = min(abs(levels - wave(i)));
    self.wave(i) = levels(loc); 
end

%stimVal = gammaCorrect(self.meanLevelRaw+levels(a)/2
S = resample(wave,frameDwell,1); %now in frames
S = resample(S,stimPoints,spatial_stimpts); %now in samples
extraPoints = stimPoints_collected - stimPoints;
S = [S zeros(1,extraPoints)];
