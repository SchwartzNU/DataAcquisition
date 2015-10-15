classdef ContrastResponse < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.ContrastResponse'
        version = 2
        displayName = 'Contrast Response'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 1000 %will be rounded to account for frame rate
        stimTime = 500 %will be rounded to account for frame rate
        tailTime = 1000 %will be rounded to account for frame rate
        
        %mean (bg) and amplitude of pulse        
        contrastNSteps = 5
        minContrast = .02
        maxContrast = 1
        contrastDirection 
        
        spotSize = 300; %microns
        
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Hidden)
        contrastValues
        intensityValues
        contrast
        intensity
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
                    p.units = 'um'; 
                    p.displayTab = 'mostUsed';
                case 'meanIntensity'
                    p.units = 'rel';
                case 'contrastDirection'
                    p.defaultValue = {'both', 'positive', 'negative'};
                    p.displayTab = 'mostUsed';
                case 'meanLevel'
                    p.defaultValue = 0.5;
                case {'contrastNSteps', 'minContrast', 'maxContrast'}
                    p.displayTab = 'mostUsed';
            end
        end

        function prepareRun(obj)
            global DEMO_MODE;
            %force 8 bit
            obj.bitDepth = 8;
            
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set contrast and intensity values
            if strcmp(obj.contrastDirection, 'positive')
                obj.contrastValues = 2.^linspace(log2(obj.minContrast),log2(obj.maxContrast),obj.contrastNSteps);
            elseif strcmp(obj.contrastDirection, 'negative')
                obj.contrastValues = -2.^linspace(log2(obj.minContrast),log2(obj.maxContrast),obj.contrastNSteps);
            else
                posSteps =  2.^linspace(log2(obj.minContrast),log2(obj.maxContrast),obj.contrastNSteps);
                negSteps = -2.^linspace(log2(obj.minContrast),log2(obj.maxContrast),obj.contrastNSteps);
                obj.contrastValues = [fliplr(negSteps), posSteps];
            end
            %obj.contrastValues            
            obj.intensityValues = obj.meanLevel + (obj.contrastValues.*obj.meanLevel);
            %obj.intensityValues
            
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'contrast'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'contrast', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'Mode', 'Whole cell', ...
                        'LineStyle', '-', ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {'contrast'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'contrast', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'Mode', 'Whole cell', ...
                        'LineStyle', '-', ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'contrast'}, ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                         'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'contrast', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'Mode', 'Cell attached', ...
                        'LineStyle', '-', ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'contrast'}, ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                         'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'contrast', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'Mode', 'Cell attached', ...
                        'LineStyle', '-', ...
                        'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                        'LineColor', 'r');
                    end
                end
            end
            
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            if strcmp(obj.contrastDirection, 'both')
                numContrastSteps = obj.contrastNSteps*2;
            else
                numContrastSteps = obj.contrastNSteps;
            end
            
            % compute current contrast index
            contrastValInd = mod(obj.numEpochsQueued, numContrastSteps) + 1;
            
            % Randomize values if this is a new set
            if mod(obj.numEpochsQueued, numContrastSteps) == 0
                reorder = randperm(length(obj.contrastValues));
                obj.contrastValues = obj.contrastValues(reorder);
                obj.intensityValues = obj.intensityValues(reorder);
            end
            
            %get current contrast
            obj.contrast = obj.contrastValues(contrastValInd);
            %disp(obj.contrast)
            %disp(['contrast signal = ' num2str(obj.contrast)]);
            obj.intensity = obj.intensityValues(contrastValInd);
            %disp(obj.intensity)
            %disp(['intensity = ' num2str(obj.intensity)]);
            epoch.addParameter('contrast', obj.contrast);
            epoch.addParameter('intensity', obj.intensity); 
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            spot = Ellipse();
            spot.radiusX = round(obj.spotSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
            spot.radiusY = spot.radiusX;
            spot.color = obj.intensity;
            spot.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            presentation.addStimulus(spot);
            
            function opacity = onDuringStim(state, preTime, stimTime)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    opacity = 1;
                else
                    opacity = 0;
                end
            end
            
            controller = PropertyController(spot, 'opacity', @(s)onDuringStim(s, obj.preTime, obj.stimTime));
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
        
        function pn = parameterNames(obj, includeConstant)
            if nargin == 1
                pn = parameterNames@StageProtocol(obj);
            else
                pn = parameterNames@StageProtocol(obj, includeConstant);
            end
            
            % Force 8 bit for contrast response function
            pn = pn(~strncmp(pn, 'bitDepth', 8));
        end
        
    end
    
end