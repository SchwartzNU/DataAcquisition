classdef RotatingBox < StageProtocol
    
    properties (Constant)
        identifier = 'edu.washington.rieke.RotatingBox'
        version = 1
        displayName = 'Rotating Box'
    end
    
    properties
        amp
        preTime = 50
        stimTime = 500
        tailTime = 50
        speed = 100
    end
    
    properties
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function preparePresentation(obj, presentation)
            preparePresentation@StageProtocol(obj, presentation);
            
            rect = Rectangle();
            rect.position = [obj.windowSize(1), obj.windowSize(2)/2]; %this is centered - need to deal with this projection issue
            presentation.addStimulus(rect);
            presentation.addController(rect, 'orientation', @(s)s.time*obj.speed);
            presentation.addController(rect, 'size', @(s)[s.time*obj.speed, s.time*obj.speed]);
            
            rect2 = Rectangle();
            rect2.opacity = 0.5;
            rect2.position = [obj.windowSize(1), obj.windowSize(2)/2];%this is centered - need to deal with this projection issue
            presentation.addStimulus(rect2);
            presentation.addController(rect2, 'orientation', @(s)s.time*-obj.speed);
            presentation.addController(rect2, 'size', @(s)[s.time*obj.speed, s.time*obj.speed]);
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