classdef ExamplePulseFamily < SymphonyProtocol
    
    properties (Constant)
        identifier = 'io.github.symphony-das.ExamplePulseFamily'
        version = 1
        displayName = 'Example Pulse Family'
    end
    
    properties
        amp
        preTime = 50
        stimTime = 500
        tailTime = 50
        firstPulseSignal = 100
        incrementPerPulse = 10
        pulsesInFamily = uint16(11)
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
                case {'firstPulseSignal', 'incrementPerPulse', 'preAndTailSignal', 'ampHoldSignal'}
                    p.units = 'mV or pA';
                case 'interpulseInterval'
                    p.units = 's';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@SymphonyProtocol(obj);
            
            % Set the amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'mV');
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'pA');
            end
            
            % Open figures showing the response and mean response of the amp.
            obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'pulseSignal'});
            obj.openFigure('Response', obj.amp);
        end
        
        
        function [stim, pulseSignal] = ampStimulus(obj, pulseNum)
            % Calculate a pulse signal for the pulse number.
            pulseSignal = obj.incrementPerPulse * (pulseNum - 1) + obj.firstPulseSignal;
            
            % Construct a pulse stimulus generator.
            p = PulseGenerator();
            
            % Assign generator properties.
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = pulseSignal - obj.preAndTailSignal;
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
            % Return an array of sample stimuli for display in the edit parameters window.
            stimuli = cell(obj.pulsesInFamily, 1);
            for i = 1:obj.pulsesInFamily         
                stimuli{i} = obj.ampStimulus(i);
            end
        end
        
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@SymphonyProtocol(obj, epoch);
            
            % Add the amp pulse stimulus to the epoch.
            pulseNum = mod(obj.numEpochsQueued, obj.pulsesInFamily) + 1;
            [stim, pulseSignal] = obj.ampStimulus(pulseNum);
            
            epoch.addParameter('pulseSignal', pulseSignal);
            epoch.addStimulus(obj.amp, stim);
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
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            % Keep going until the requested number of epochs is reached.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
    end
    
end