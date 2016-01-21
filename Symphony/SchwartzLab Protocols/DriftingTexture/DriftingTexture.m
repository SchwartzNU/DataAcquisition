classdef DriftingTexture < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.DriftingTexture'
        version = 1
        displayName = 'Drifting Texture'
    end
    
    properties
        amp
        %times in ms
        preTime = 250; %will be rounded to account for frame rate
        tailTime = 250; %will be rounded to account for frame rate
        stimTime = 4000; %will be rounded to account for frame rate    
        
        movementDelay = 200;
        
        %in microns, use rigConfig to set microns per pixel
        textureWidth = 1500;
        textureScale = 100;
        speed = 1000; %um/s
        uniformDistribution = false;

        Nangles = 12;
    end

    properties
        numberOfAverages = uint16(5)
        %interpulse interval in sec
        interpulseInterval = 0
        apertureDiameter = 0;
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
            end
        end
        

        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set directions
            obj.angles = rem(0:round(360/obj.Nangles):359, 360);
            
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'gratingAngle'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'gratingAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'PlotType', 'Polar');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {'gratingAngle'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'barAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'PlotType', 'Polar', 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'gratingAngle'}, ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'gratingAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                        'Mode', 'Cell attached', 'PlotType', 'Polar');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'gratingAngle'}, ...
                            'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                           'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'gratingAngle', ...
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
            
            % Randomize angles if this is a new set
            if mod(obj.numEpochsQueued, obj.Nangles) == 0
               obj.angles = obj.angles(randperm(obj.Nangles));
            end
            
            % compute current angle and add parameter to the epoch
            angleInd = mod(obj.numEpochsQueued, obj.Nangles) + 1;
            
            obj.curAngle = obj.angles(angleInd); %make it a property so preparePresentation has access to it
            epoch.addParameter('textureAngle', obj.curAngle);
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            sigma = obj.textureScale / obj.rigConfig.micronsPerPixel % pixels
            dist = obj.speed * obj.stimTime / 1000 % um / sec
            res = 1100 + 2 * (dist / obj.rigConfig.micronsPerPixel) % pixels
            M = randn(res);
            %             M = imgaussfilt(M, sigma); % code for a more enlightened era
            
            winL = 200; %size of smoothing factor window
            rng(1); %set random seed
            win = fspecial('gaussian',winL,sigma);
            win = win ./ sum(win(:));
            M = imfilter(M,win,'replicate');
            
            if obj.uniformDistribution
                M = makeUniformDist(M);
            else
                M = zscore(M) * 0.5 + 0.5;
                M(M < 0) = 0;
                M(M > 1) = 1;
            end
            M = uint8(255 * M);
            im = Image(M);
            im.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            im.size = [res, res];
            presentation.addStimulus(im);
            
%             pixelSpeed = obj.gratingSpeed./obj.rigConfig.micronsPerPixel;
            
            % circular aperture mask (only gratings in center)
            if obj.apertureDiameter > 0
                apertureDiameterRel = obj.apertureDiameter / max(obj.gratingLength, obj.gratingWidth);
                mask = Mask.createCircularEnvelope(2048, apertureDiameterRel);
                im.setMask(mask);
            end

            % Gratings drift controller
            function pos = movementController(state, duration, preTime, movementDelay, tailTime, angle)
                startMovementTime = (preTime/1E3 + movementDelay/1E3);
                if state.time<=preTime/1E3 || state.time>duration-tailTime/1E3 %in pre or tail time
                    %off screen
                    pos = [NaN, NaN];
                else
                    %on screen
                    pos = [obj.windowSize(1)/2, obj.windowSize(2)/2]; 
                end
                if state.time > startMovementTime
                    %then change phase
                    t = state.time - startMovementTime;
                    y = obj.speed * sind(angle) * t;
                    x = obj.speed * cosd(angle) * t;
                    pos = [x,y] + [obj.windowSize(1)/2, obj.windowSize(2)/2];
                end
            end
            controller = PropertyController(im, 'position', @(s)movementController(s, presentation.duration, obj.preTime, obj.movementDelay, obj.tailTime));            
            presentation.addController(controller);
            
            
            % circular block mask (only gratings outside center)
%             function opacity = onDuringStim(state, preTime, stimTime)
%                 if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
%                     opacity = 1;
%                 else
%                     opacity = 0;
%                 end
%             end

            if obj.apertureDiameter < 0
                spot = Ellipse();
                spot.radiusX = round(obj.apertureDiameter / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
                spot.radiusY = spot.radiusX;
                spot.color = obj.meanLevel;
                spot.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
                presentation.addStimulus(spot);
            end
%             centerCircleController = PropertyController(spot, 'opacity', @(s)onDuringStim(s, obj.preTime, obj.stimTime));
%             presentation.addController(centerCircleController);
            
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