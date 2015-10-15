classdef AlignmentCross < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.AlignmentCross'
        version = 1
        displayName = 'Alignment Cross'
    end
    
    properties
        amp
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 500 %will be rounded to account for frame rate
        tailTime = 0 %will be rounded to account for frame rate
        
        %intensity of cross
        intensity = 0.5;
        
        %stim size in microns, use rigConfig to set microns per pixel
        width = 10;
        length = 200;
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
            end
        end
        
        function preparePresentation(obj, presentation)
            preparePresentation@StageProtocol(obj, presentation);
            
            rect1 = Rectangle();
            rect1.size = [obj.width, obj.length];
            rect1.color = obj.intensity;
            rect1.position = [obj.windowSize(1)/2, obj.windowSize(2)/2]; %this is centered - need to deal with this projection issu
            presentation.addStimulus(rect1);
                        
            rect2 = Rectangle();
            rect2.size = [obj.length, obj.width];
            rect2.color = obj.intensity;
            rect2.position = [obj.windowSize(1)/2, obj.windowSize(2)/2]; %this is centered - need to deal with this projection issu
            presentation.addStimulus(rect2);
            
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
            
            % Hide hold signal parameters since they are changing each
            % epoch
            pn = pn(~strncmp(pn, 'ampHoldSignal', 14));
            pn = pn(~strncmp(pn, 'amp2HoldSignal', 14));
            pn = pn(~strncmp(pn, 'ampMode', 14));
            pn = pn(~strncmp(pn, 'amp2Mode', 14));
            pn = pn(~strncmp(pn, 'RstarMean', 9));
            pn = pn(~strncmp(pn, 'meanLevel', 9));
            pn = pn(~strncmp(pn, 'NDF', 3));
        end
        
    end
    
end