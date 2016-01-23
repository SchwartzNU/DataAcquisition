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
        stimTime = 1000; %will be rounded to account for frame rate    
        
        movementDelay = 200;
        
        %in microns, use rigConfig to set microns per pixel
        textureScale = 100;
        speed = 1000; %um/s
        uniformDistribution = false;
        numberOfCycles = 2;
        Nangles = 12;
    end

    properties
        
        %interpulse interval in sec
        interpulseInterval = 0
        apertureDiameter = 0;
    end
        
    properties (Hidden)
       curAngle
       angles
       imageMatrix
       moveDistance
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
            
            % generate texture
            sigma = obj.textureScale / obj.rigConfig.micronsPerPixel; % pixels
            dist = obj.speed * obj.stimTime / 1000; % um / sec
            obj.moveDistance = dist;
            res = [max(obj.windowSize) * 1.42 + (dist / obj.rigConfig.micronsPerPixel),...
                   max(obj.windowSize) * 1.42, ]; % pixels
            res = round(res);
            
            fprintf('making texture (%d x %d)\n', res(1), res(2));

            M = randn(res);
            %             M = imgaussfilt(M, sigma); % code for a more enlightened era
            
            winL = max(2*sigma, round(min(res) / 5)); %size of smoothing factor window
            rng(1); %set random seed
            filtWin = fspecial('gaussian',winL,sigma);
            filtWin = filtWin ./ sum(filtWin(:));
            M = imfilter(M,filtWin,'replicate');
%             
%             M = abs(M) ./ max(M(:)) * 2 + 0.5;
%             
            if obj.uniformDistribution
                M = makeUniformDist(M);
            else
                M = zscore(M(:)) * 0.5 + 0.5;
                M = reshape(M, res);
                M(M < 0) = 0;
                M(M > 1) = 1;
            end
%             M = checkerboard_bi(10);
%             M = horzcat(M,M);
            obj.imageMatrix = uint8(255 * M);
            disp('done');
            
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
            
            
            im = Image(obj.imageMatrix);
            im.orientation = obj.curAngle + 90;
%             im.size = [1,2] * 100;
            im.size = fliplr(size(obj.imageMatrix));
            presentation.addStimulus(im);
            
            pixelSpeed = obj.speed / obj.rigConfig.micronsPerPixel;

            % Gratings drift controller
            function pos = movementController(state, stimTime, preTime, movementDelay, pixelSpeed, angle)
                t = state.time;
                duration = stimTime / 1000;
                shapeOnTime = preTime / 1000;
                startMovementTime = shapeOnTime + movementDelay/1000;
                endMovementTime = startMovementTime + stimTime/1000;
                
                if t < shapeOnTime
                    pos = [NaN, NaN];
                elseif t < startMovementTime
                    y = pixelSpeed * sind(angle) * (0 - duration/2);
                    x = pixelSpeed * cosd(angle) * (0 - duration/2);
                    pos = [x,y] + [obj.windowSize(1)/2, obj.windowSize(2)/2];
%                 else
                elseif t < endMovementTime
                    timeFromStartMovement = t - startMovementTime;
                    y = pixelSpeed * sind(angle) * (timeFromStartMovement - duration/2);
                    x = pixelSpeed * cosd(angle) * (timeFromStartMovement - duration/2);
                    pos = [x,y] + [obj.windowSize(1)/2, obj.windowSize(2)/2];
                else
                    pos = [NaN, NaN];
                end
            end
            controller = PropertyController(im, 'position', @(s)movementController(s, obj.stimTime, obj.preTime, obj.movementDelay, pixelSpeed, obj.curAngle));            
            presentation.addController(controller);
            
           
            % circular aperture mask (only gratings in center)
            if obj.apertureDiameter > 0
                apertureDiameterRel = obj.apertureDiameter / max(obj.gratingLength, obj.gratingWidth);
                mask = Mask.createCircularEnvelope(2048, apertureDiameterRel);
                im.setMask(mask);
            end
            
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
            
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numberOfCycles * obj.Nangles;
            end
        end
                
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@StageProtocol(obj);
            
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfCycles * obj.Nangles;
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