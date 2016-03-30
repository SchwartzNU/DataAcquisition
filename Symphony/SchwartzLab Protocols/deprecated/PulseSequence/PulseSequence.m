classdef PulseSequence < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.PulseSequence'
        version = 1
        displayName = 'Pulse Sequence'
    end
    
    properties
        amp
        ampHoldSignal = 0
        amp2HoldSignal = 0
        preTime = 500 
        stimTime = 500
        tailTime = 500
        startAmplitude = 2 %mV or pA
        nSteps = 5;
        scaleExponent = 2;
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end
    
    properties (Hidden)
       amplitudeSet 
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties (Dependent)
        maxAmplitude
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case {'startAmplitude', 'ampHoldSignal','amp2HoldSignal', 'maxAmplitude'}
                    p.units = 'mV or pA';
                    p.displayTab = 'mostUsed';
                case {'nSteps', 'scaleExponent'}
                    p.displayTab = 'mostUsed';
                case {'ampMode', 'amp2Mode'}
                    p.defaultValue = {'Whole cell', 'Cell attached'};
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Set amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'mV');
%                 if ~isempty(obj.amp2)
%                     obj.setDeviceBackground(obj.amp2, obj.amp2HoldSignal, 'mV');
%                 end
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'pA');
%                 if ~isempty(obj.amp2)
%                     obj.setDeviceBackground(obj.amp2, obj.amp2HoldSignal, 'pA');
%                 end
            end
            
            %set amplitude list (doublings)
            obj.amplitudeSet = zeros(1, obj.nSteps);
            obj.amplitudeSet(1) = obj.startAmplitude;
            for i=2:obj.nSteps
                obj.amplitudeSet(i) = round(obj.amplitudeSet(i-1)*obj.scaleExponent);
            end
            
            % Open figures for single trial responses of both amps
            obj.openFigure('Response', obj.amp);
            if ~isempty(obj.amp2)
                 obj.openFigure('Response', obj.amp2, 'LineColor', 'r');
            end
            
            % Open figures showing the mean response of the amp.
            obj.openFigure('Mean Response', obj.amp);
            if ~isempty(obj.amp2)
                if strcmp(obj.amp2Mode, 'Whole cell') 
                    obj.openFigure('Mean Response', obj.amp2, 'LineColor', 'r'); 
                elseif strcmp(obj.amp2Mode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                end
            end
        end
        
        
        function stim = ampStimulus(obj, ampVal)
            % Construct a pulse stimulus generator.
            p = PulseGenerator();
            
            % Assign generator properties.
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = ampVal;
            p.mean = obj.ampHoldSignal;
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
            stimuli{1} = obj.ampStimulus(obj.startAmplitude);
%             for i=2:obj.nSteps
%                 stimuli{i} = obj.ampStimulus(round(obj.amplitudeSet(i-1)*obj.scaleExponent));
%             end
            
        end
        
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % get current amplitude and add parameter for it   
            ind = mod(obj.numEpochsQueued, obj.nSteps) + 1;
            curAmplitude = obj.amplitudeSet(ind); %make it a property so preparePresentation has access to it
            epoch.addParameter('pulseAmplitude', curAmplitude);
            
            % Add the amp pulse stimulus to the epoch.
            epoch.addStimulus(obj.amp, obj.ampStimulus(curAmplitude));  
        end
        
        
        function queueEpoch(obj, epoch)            
            % Call the base method to queue the actual epoch.
            queueEpoch@PulsedProtocol(obj, epoch);
            
            % Queue an inter-pulse interval after queuing the epoch.
            if obj.interpulseInterval > 0
                obj.queueInterval(obj.interpulseInterval);
            end
        end        
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@PulsedProtocol(obj);
            
            % Keep queuing until the requested number of averages have been queued.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < obj.numberOfAverages;
            end
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@PulsedProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numberOfAverages;
            end
        end
        
        function maxAmplitude = get.maxAmplitude(obj)
            maxAmplitude = round(obj.startAmplitude * obj.scaleExponent^(obj.nSteps-1));
        end
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
    
end