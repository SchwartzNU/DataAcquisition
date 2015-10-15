classdef FlashMultiDuration < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.FlashMultiDuration'
        version = 1
        displayName = 'Flashes Multiple Durations'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        durationStart = 10; %ms
        spacingFactor = 1.6; %exponent for logorithmmic scale
        durationSteps = 8;
        
        %stim size in microns, use rigConfig to set microns per pixel
        spotSize = 250;
        
        intensity = 0.5;

    
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
     
    properties (Hidden)
       durationList
       stimTime 
    end
    
    properties (Dependent)
        durationEnd
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
                case {'durationStart', 'durationEnd'}
                    p.displayTab = 'mostUsed';
                    p.units = 'ms';
                case {'durationSteps', 'spacingFactor'}
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
            
            %set durations
            obj.durationList = obj.durationStart.*obj.spacingFactor.^(0:obj.durationSteps-1);
            %rounding for current bit depth
  
            frameInterval = 1./(60*obj.patternsPerFrame) .*1000; %ms
            framesPerStim = round(obj.durationList./frameInterval);
            obj.durationList = frameInterval.*framesPerStim;
            obj.durationList
%             obj.bitDepth
            
            obj.stimTime = obj.durationList(1);
            
            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp,  'GroupByParams', {'stimTime'});
                     obj.openFigure('1D Response', obj.amp, 'EpochParam', 'stimTime', ...
                         'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2,  'GroupByParams', {'stimTime'}, ...
                           'LineColor', 'r');
                         obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'stimTime', ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'stimTime'}, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'stimTime', ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                        'Mode', 'Cell attached');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'stimTime'}, ...
                         'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                         'LineColor', 'r');
                     obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'stimTime', ...
                            'Mode', 'Cell attached', ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                    end
                end
            end
        end
        
        function prepareEpoch(obj, epoch)            
            % compute current duration and add parameters to the epoch       
            durationInd = mod(obj.numEpochsQueued, obj.durationSteps) + 1;
            
            %get current stimTime = duration
            obj.stimTime = obj.durationList(durationInd);             
            
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            epoch.addParameter('stimTime', obj.stimTime); 
        end
             
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            spot = Ellipse();
            spot.radiusX = round(obj.spotSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
            spot.radiusY = spot.radiusX;
            %spot.color = obj.intensity;
            spot.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            presentation.addStimulus(spot);
            
            function c = onDuringStim(state, preTime, stimTime, intensity, meanLevel)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    c = intensity;
                else
                    c = meanLevel;
                end
            end
            
            controller = PropertyController(spot, 'color', @(s)onDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
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
  
        function durationEnd = get.durationEnd(obj)
            %dependent, for logarithmic spacing duration axis;
            durationEnd = obj.durationStart.*obj.spacingFactor^(obj.durationSteps-1);
        end
   
    end
    
end