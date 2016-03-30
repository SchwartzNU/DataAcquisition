classdef Looming < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.Looming'
        version = 1
        displayName = 'Looming'
    end
    
    properties
        amp
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        %mean (bg) and amplitude of pulse
        intensity = 1;
        
        %stim size in microns, use rigConfig to set microns per pixel
        startSize = 10 %um
        endSize = 500 %um
        holdTime = 250 %ms
        speed = 1000 %um/s
    end
    
    properties (Dependent)
        stimTime
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case 'speed'
                    p.displayTab = 'mostUsed';
                    p.units = 'um/s';
                case {'startSize', 'endSize'}
                    p.displayTab = 'mostUsed';
                    p.units = 'um';
                case 'holdTime'
                    p.units = 'ms';
            end
        end
        
        
        function prepareRun(obj)
            global DEMO_MODE;
            
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            % Open figures showing the response and mean response of the amp.
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                            'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                            'LineColor', 'r');
                    end
                end
            end
        end
        
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            spot = Ellipse();
            spot.color = obj.intensity;
            spot.position = [obj.windowSize(1)/2, obj.windowSize(2)/2]; %this is centered - need to deal with this projection issu
            presentation.addStimulus(spot);
            startSize_pix = round(obj.startSize/obj.rigConfig.micronsPerPixel);
            endSize_pix = round(obj.endSize/obj.rigConfig.micronsPerPixel);
            speed_pix = round(obj.speed/obj.rigConfig.micronsPerPixel);
            
            function r = radiusController(time, startSize, endSize, speed, preTime, holdTime)
                if endSize > startSize
                    loomingTime = (endSize - startSize) / speed;
                else
                    loomingTime = (startSize - endSize) / -speed;
                end
                timeInLoom = time - (preTime+holdTime)*1e-3;
                
                if time < preTime*1e-3 %preTime
                    r = 0;
                elseif time < (preTime+holdTime)*1e-3 %hold at startSize
                    r = startSize;
                elseif time < (preTime+holdTime)*1e-3 + loomingTime %looming
                    r = startSize + speed*timeInLoom;
                elseif time < (preTime+holdTime*2)*1e-3 + loomingTime %hold at endSize
                    r = endSize;
                else %postTime
                    r = 0;
                end
            end
            
            controllerX = PropertyController(spot, 'radiusX', @(s)radiusController(s.time, ...
                startSize_pix,endSize_pix,speed_pix, obj.preTime, obj.holdTime));
            controllerY = PropertyController(spot, 'radiusY', @(s)radiusController(s.time, ...
                startSize_pix,endSize_pix,speed_pix, obj.preTime, obj.holdTime));
            presentation.addController(controllerX);
            presentation.addController(controllerY);
            
            preparePresentation@StageProtocol(obj, presentation); %adds frameTracker
            
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
        
        function stimTime = get.stimTime(obj)
            if obj.endSize > obj.startSize
                loomingTime = round(1E3*(obj.endSize/obj.rigConfig.micronsPerPixel - obj.startSize/obj.rigConfig.micronsPerPixel) / ...
                    (obj.speed/obj.rigConfig.micronsPerPixel));
            else
                loomingTime = round(1E3*(obj.startSize/obj.rigConfig.micronsPerPixel - obj.endSize/obj.rigConfig.micronsPerPixel) / ...
                    (-obj.speed/obj.rigConfig.micronsPerPixel));
            end
            stimTime = obj.holdTime * 2 + loomingTime;
        end
        
    end
    
end