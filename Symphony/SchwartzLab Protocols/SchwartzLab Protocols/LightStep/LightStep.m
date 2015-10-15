classdef LightStep < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.LightStep'
        version = 1
        displayName = 'Light Step'
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
        spotSize = 300;
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Hidden)
       patternTrig 
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
                case 'meanIntensity'
                    p.units = 'rel';
            end
        end
        
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %get trigger device
            obj.patternTrig = obj.rigConfig.deviceWithName('PatternTrigger');

            if ~DEMO_MODE
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
                    obj.openFigure('PSTH', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                    end
                end
            end
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
            
            presentation.addController(spot, 'color', @(s)onDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
            
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