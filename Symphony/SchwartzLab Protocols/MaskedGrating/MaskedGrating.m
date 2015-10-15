classdef MaskedGrating < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.MaskedGrating'
        version = 1
        displayName = 'Masked Grating'
    end
    
    properties
        amp
        %times in ms
        preTime = 250 %will be rounded to account for frame rate
        tailTime = 250 %will be rounded to account for frame rate
        stimTime = 500
        fadeTime = 100
        
        %in microns, use rigConfig to set microns per pixel
        gratingSpacing = 20;
        gratingSpeed = 300; %um/s
        maskWidth = 200;

        Nangles = 8;
        intensity = 0.5;
        startAngle = 0;
    end

    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
        
    properties (Hidden)
       curAngle
       angles 
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case 'gratingSpeed'
                    p.displayTab = 'mostUsed';
                    p.units = 'um/s';
                case {'gratingSpacing', 'maskWidth'}
                    p.units = 'um';
                    p.displayTab = 'mostUsed';
                case {'Nangles', 'startAngle'}
                    p.displayTab = 'mostUsed';
            end
        end
        

        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set directions
            obj.angles = rem(obj.startAngle:round(360/obj.Nangles):obj.startAngle+359, 360);
            
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'barAngle'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'barAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'PlotType', 'Polar');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {'barAngle'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'barAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'PlotType', 'Polar', 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'barAngle'}, ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'barAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                        'Mode', 'Cell attached', 'PlotType', 'Polar');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'barAngle'}, ...
                            'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                           'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'barAngle', ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'Mode', 'Cell attached', 'PlotType', 'Polar', ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                    end
                end
            end
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            % compute current angle and add parameter to the epoch       
            angleInd = mod(obj.numEpochsQueued, obj.Nangles) + 1;
            
            % Randomize angles if this is a new set
            if mod(obj.numEpochsQueued, obj.Nangles) == 0
               obj.angles = obj.angles(randperm(obj.Nangles)); 
            end
            
            obj.curAngle = obj.angles(angleInd); %make it a property so preparePresentation has access to it
            epoch.addParameter('barAngle', obj.curAngle);
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            % Create the grating stimulus.
            grating = Grating('square',512);
            grating.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            grating.size = [512, 512];
            grating.orientation = obj.curAngle;
            grating.spatialFreq = 1 / (obj.gratingSpacing / obj.rigConfig.micronsPerPixel);

            % Assign a gaussian envelope mask to the grating.
            fwhmPixels = obj.maskWidth / obj.rigConfig.micronsPerPixel;
            gaussianSigma = fwhmPixels / 256 / 2.355; % gaussian is -1:1 for 512 px, so 256 px = 1 gaussian unit
            mask = Mask.createGaussianEnvelope(512, gaussianSigma);
            grating.setMask(mask);

            % Create a controller to change the grating's phase property as a function of time. The phase will shift 360 degrees 
            % per second.
            timeFrequency = 360 * (obj.gratingSpeed / obj.gratingSpacing);
            gaborPhaseController = PropertyController(grating, 'phase', @(state)state.time * timeFrequency);

            % fade grating in & out to avoid strong initial ON/OFF responses
            function c = fadeInOut(state, preTime, stimTime, intensity, fadeTime)
                startFadeIn = preTime - fadeTime/2;
                endFadeIn = preTime + fadeTime/2;
                startFadeOut = (preTime+stimTime) - fadeTime/2;
                endFadeOut = (preTime+stimTime) + fadeTime/2;
                
                tms = state.time*1000;
                
                if tms < startFadeIn
                    c = 0;
                elseif tms < endFadeIn
                    c = intensity * (tms - startFadeIn)/fadeTime;
                elseif tms < startFadeOut
                    c = intensity;
                elseif tms < endFadeOut
                    c = intensity * (1 - (tms - startFadeOut)/fadeTime);
                else
                    c = 0;
                end
                
            end
            
            
            fadeController = PropertyController(grating, 'color', @(state)fadeInOut(state, obj.preTime, obj.stimTime, obj.intensity, obj.fadeTime));
            
            presentation.addStimulus(grating);
            presentation.addController(gaborPhaseController);
            presentation.addController(fadeController);
            
%             
%             spot = Ellipse();
%             spot.radiusX = round(obj.maskWidth / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
%             spot.radiusY = spot.radiusX;
%             spot.color = 1;
%             spot.opacity = 0.1;
%             spot.position = [obj.windowSize(1)/2.3, obj.windowSize(2)/2];
%             presentation.addStimulus(spot);
%             
            
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
            
            % hide params
            pn = pn(~strcmp(pn, 'preTime'));
            pn = pn(~strcmp(pn, 'tailTime'));
            
        end

    end
    
end