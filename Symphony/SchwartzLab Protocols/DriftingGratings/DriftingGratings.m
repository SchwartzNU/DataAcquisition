classdef DriftingGratings < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.DriftingGratings'
        version = 2
        displayName = 'Drifting Gratings'
    end
    
    properties
        amp
        %times in ms
        preTime = 250; %will be rounded to account for frame rate
        tailTime = 250; %will be rounded to account for frame rate
        stimTime = 1000; %will be rounded to account for frame rate    
        
        movementDelay = 200;
        
        %in microns, use rigConfig to set microns per pixel
        gratingWidth = 1500;
        gratingLength = 1500;
        gratingSpeed = 1000; %um/s
        cycleHalfWidth = 50; %um
        apertureDiameter = 0; %um
        squareOnFraction = 0.5;
        centerMaskIntensity = 0;
        
        gratingProfile = 'sine'; %sine or square
        
        Nangles = 12;
        contrast = 1;
        startAngle = 0;
    end
    
    properties (Dependent)
        spatialFreq %cycles/degree
        temporalFreq %cycles/s (Hz)
    end

    properties
        numberOfAverages = uint16(5)
        %interpulse interval in sec
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
                case {'gratingWidth', 'gratingLength'}
                    p.units = 'um';
                    p.displayTab = 'mostUsed';
                case {'Nangles', 'startAngle'}
                    p.displayTab = 'mostUsed';
                case 'gratingProfile'
                    p.defaultValue = {'sine','square'};
                    p.displayTab = 'mostUsed';
                case 'spatialFreq'
                    p.displayTab = 'mostUsed';
                    p.units = 'cpd';
                case 'temporalFreq'
                    p.displayTab = 'mostUsed';
                    p.units = 'Hz';
                case 'cycleHalfWidth'
                    p.displayTab = 'mostUsed';
                    p.units = 'um';
                case 'movementDelay'
                    p.displayTab = 'protocol';
                    p.units = 'ms';
                case 'apertureDiameter'
                    p.units = 'um';
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
            epoch.addParameter('gratingAngle', obj.curAngle);
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            %grat = Grating();
            grat = Grating(obj.gratingProfile, 1024, obj.squareOnFraction);
            grat.orientation = obj.curAngle;
            grat.contrast = obj.contrast;
            grat.size = round([obj.gratingLength, obj.gratingWidth]./obj.rigConfig.micronsPerPixel);
            grat.spatialFreq = obj.rigConfig.micronsPerPixel/(2*obj.cycleHalfWidth);
            presentation.addStimulus(grat);
%             pixelSpeed = obj.gratingSpeed./obj.rigConfig.micronsPerPixel;
            
            % circular aperture mask (only gratings in center)
            if obj.apertureDiameter > 0
                apertureDiameterRel = obj.apertureDiameter / max(obj.gratingLength, obj.gratingWidth);
                mask = Mask.createCircularEnvelope(2048, apertureDiameterRel);
                grat.setMask(mask);
            end

            % Gratings drift controller
            function pos = movementController(state, duration, preTime, movementDelay, tailTime)
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
                    grat.phase = 360*obj.temporalFreq*(state.time - startMovementTime);
                end
            end
            controller = PropertyController(grat, 'position', @(s)movementController(s, presentation.duration, obj.preTime, obj.movementDelay, obj.tailTime));            
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
                spot.color = obj.centerMaskIntensity;
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
        
        function spatialFreq = get.spatialFreq(obj)
            % 1 deg visual angle = 30um (mouse retina)
            micronperdeg = 30;
            spatialFreq = micronperdeg/(2*obj.cycleHalfWidth);
        end
        
        function temporalFreq = get.temporalFreq(obj)
            temporalFreq = obj.gratingSpeed/(2*obj.cycleHalfWidth);
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