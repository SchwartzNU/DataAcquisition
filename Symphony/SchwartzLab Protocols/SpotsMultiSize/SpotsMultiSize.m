classdef SpotsMultiSize < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.SpotsMultiSize'
        version = 2
        displayName = 'Spots Multiple Sizes'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        %mean (bg) and amplitude of pulse
        intensity = 0.1;
        
        %stim size in microns, use rigConfig to set microns per pixel
        minSize = 50
        Nsteps = 10
        maxSize = 1500
    end
    
    properties
        numberOfAverages = uint16(10)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Hidden)
        curSize
        sizeVec
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case {'intensity', 'meanLevel'}
                    p.units = 'rel';
                case {'minSize', 'maxSize'}
                    p.units = 'um';
                    p.displayTab = 'mostUsed';
                case 'Nsteps'
                    p.displayTab = 'mostUsed';
            end
        end
        
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set spot size vector
            obj.sizeVec = linspace(obj.minSize, obj.maxSize, obj.Nsteps);
            
            
            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', 'curSpotSize', 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curSpotSize', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', 'curSpotSize', 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'curSpotSize', ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                            'Mode', 'Whole cell', 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', 'curSpotSize', ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curSpotSize', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'Mode', 'Cell attached', ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', 'curSpotSize', ...
                            'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curSpotSize', ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'Mode', 'Cell attached', ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                    end
                end
            end
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            % Randomize sizes if this is a new set
            if mod(obj.numEpochsQueued, obj.Nsteps) == 0
               obj.sizeVec = obj.sizeVec(randperm(obj.Nsteps)); 
            end
            
            % compute current size and add parameter for it
            sizeInd = mod(obj.numEpochsQueued, obj.Nsteps) + 1;
            
            %get current position
            obj.curSize = obj.sizeVec(sizeInd);
            epoch.addParameter('curSpotSize', obj.curSize );
        end
        
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            spot = Ellipse();
            spot.radiusX = round(obj.curSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
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
        
        
    end
    
end