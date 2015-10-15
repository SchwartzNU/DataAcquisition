classdef ExamplePulse < SymphonyProtocol
    
    properties (Constant)
        identifier = 'io.github.symphony-das.ExamplePulse'
        version = 1
        displayName = 'Example Pulse'
    end
    
    properties
        amp
        preTime = 50
        stimTime = 500
        tailTime = 50
        pulseAmplitude = 100
        preAndTailSignal = -60
        ampHoldSignal = -60
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@SymphonyProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'amp'
                    % Prefer assigning default values in the property block above.
                    % However if a default value cannot be defined as a constant or expression, it must be defined here.
                    p.defaultValue = obj.rigConfig.multiClampDeviceNames();
                case {'preTime', 'stimTime', 'tailTime'}
                    p.units = 'ms';
                case {'pulseAmplitude', 'preAndTailSignal', 'ampHoldSignal'}
                    p.units = 'mV or pA';
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@SymphonyProtocol(obj);
            
            % Set amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'mV');
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'pA');
            end
            
            % Open figures showing the response and mean response of the amp.
            obj.openFigure('Mean Response', obj.amp);
            obj.openFigure('Response', obj.amp);
        end
        
        
        function stim = ampStimulus(obj)
            % Construct a pulse stimulus generator.
            p = PulseGenerator();
            
            % Assign generator properties.
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = obj.pulseAmplitude;
            p.mean = obj.preAndTailSignal;
            p.sampleRate = obj.sampleRate;
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                p.units = 'mV';
            else
                p.units = 'pA';
            end
            
            % Generate the stimulus object.
            stim = p.generate();
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return a sample stimulus for display in the edit parameters window.
            stimuli{1} = obj.ampStimulus();
        end
        
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@SymphonyProtocol(obj, epoch);
            
            % Add the amp pulse stimulus to the epoch.
            epoch.addStimulus(obj.amp, obj.ampStimulus());  
        end
        
        
        function queueEpoch(obj, epoch)            
            % Call the base method to queue the actual epoch.
            queueEpoch@SymphonyProtocol(obj, epoch);
            
            % Queue an inter-pulse interval after queuing the epoch.
            if obj.interpulseInterval > 0
                obj.queueInterval(obj.interpulseInterval);
            end
        end        
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@SymphonyProtocol(obj);
            
            % Keep queuing until the requested number of averages have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
            end
        end
        
    end
    
end