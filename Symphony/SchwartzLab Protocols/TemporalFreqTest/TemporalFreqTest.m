classdef TemporalFreqTest < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.TemporalFreqTest'
        version = 1
        displayName = 'Temporal frequency test'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        freqStart = 0.5;
        spacingFactor = 2; %exponent for logorithmmic scale
        freqSteps = 8;
        
        contrast = 1;
        
        %stim size in microns, use rigConfig to set microns per pixel
        spotSize = 250;
        
        stimTime = 0; %set with getStimTime, but not "dependent"
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
     
    properties (Hidden)
       freqList
       frequency 
    end
    
    properties (Dependent)
        freqEnd 
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case 'spotSize'
                    p.displayTab = 'mostUsed';
                    p.units = 'um';   
                case {'freqStart', 'freqEnd'}
                    p.displayTab = 'mostUsed';
                    p.units = 'Hz';
                case {'freqSteps', 'spacingFactor'}
                    p.displayTab = 'mostUsed';
                case {'intensity', 'meanLevel'}
                    p.displayTab = 'mostUsed';
                    p.units = 'rel';
            end
        end
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set frequencies
            obj.freqList = obj.freqStart.*obj.spacingFactor.^(0:obj.freqSteps-1);
            %rounding for current bit depth
            intervals = 1./obj.freqList;
            frameInterval = 1./(60*obj.patternsPerFrame);
            framesPerStim = round(intervals./frameInterval);
            obj.freqList = 1./(frameInterval.*framesPerStim);
            obj.freqList
            
            obj.frequency = obj.freqList(1);
            obj.stimTime = obj.getStimTime();
            
            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp,  'GroupByParams', {'curFrequency'});
                     obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curFrequency', ...
                         'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2,  'GroupByParams', {'curFrequency'}, ...
                           'LineColor', 'r');
                         obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'curFrequency', ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'curFrequency'}, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curFrequency', ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                        'Mode', 'Cell attached');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'curFrequency'}, ...
                         'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                         'LineColor', 'r');
                     obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'curSpeed', ...
                            'Mode', 'Cell attached', ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                    end
                end
            end
        end
        
        function prepareEpoch(obj, epoch)            
            % compute current freqency and add parameters to the epoch       
            freqInd = mod(obj.numEpochsQueued, obj.freqSteps) + 1;
            
            %get current frequency
            obj.frequency = obj.freqList(freqInd);             

            %set stim time
            obj.stimTime = obj.getStimTime();
            
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            epoch.addParameter('curFrequency', obj.frequency); 
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            spot = Ellipse();
            spot.radiusX = round(obj.spotSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
            spot.radiusY = spot.radiusX;
            spot.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            presentation.addStimulus(spot);
            
             function c = sineWaveStim(state, preTime, stimTime, contrast, meanLevel, freq)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    timeVal = state.time - preTime*1e-3; %s
                    %inelegant solution for zero mean
                    if meanLevel < 0.05
                        c = contrast * sin(2*pi*timeVal*freq);
                        if c<0, c = 0; end %rectify
                    else
                        c = meanLevel + meanLevel * contrast * sin(2*pi*timeVal*freq);
                    end
                else
                    c = meanLevel;
                end
            end
            
           controller = PropertyController(spot, 'color', @(s)sineWaveStim(s, obj.preTime, obj.stimTime, obj.contrast, obj.meanLevel, obj.frequency));
           presentation.addController(controller);
            
           preparePresentation@StageProtocol(obj, presentation);            
        end
        
       function queueEpoch(obj, epoch)            
            % Call the base method to queue the actual epoch.
            queueEpoch@StageProtocol(obj, epoch);
            
            % Queue the inter-pulse interval after queuing the epoch.
            if obj.interpulseInterval > 0
                obj.queueInterval(obj.interpulseInterval);
            end
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@StageProtocol(obj);
            
            % Keep queuing until the requested number of averages have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@StageProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
            end
        end
  
        function freqEnd = get.freqEnd(obj)
            %dependent, for logarithmic spacing speed axis;
            freqEnd = obj.freqStart.*obj.spacingFactor^(obj.freqSteps-1);
        end
        
        function stimTime = getStimTime(obj)
            if isempty(obj.frequency)
                stimTime = 0; %set default value before frequency is computed
            else
                %4 cycles
                stimTime = 1E3*(4/obj.frequency); %ms
            end
        end
        
    end
    
end