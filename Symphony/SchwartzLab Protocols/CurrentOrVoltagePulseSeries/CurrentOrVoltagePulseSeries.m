classdef CurrentOrVoltagePulseSeries < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.CurrentOrVoltagePulseSeries'
        version = 1
        displayName = 'Current or Voltage Pulse Series'
    end
    
    properties
        amp
        ampHoldSignal = 0
        amp2HoldSignal = 0
        preTime = 500 
        stimTime = 1000
        tailTime = 500
        minPulseAmp = 10 %mV or pA
        maxPulseAmp = 500 %mV or pA
        Nsteps = 10
        numberOfAverages = uint16(5)
        interpulseInterval = 0
        
        logScaling = false
        waitForTrigger = false; 
        
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties (Hidden)
        curAmp = 0
        AmpVec
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case {'minPulseAmp','maxPulseAmp', 'ampHoldSignal','amp2HoldSignal'}
                    p.units = 'mV or pA';
                    p.displayTab = 'mostUsed';
                case {'ampMode', 'amp2Mode'}
                    p.defaultValue = {'Whole cell', 'Cell attached'};
                case 'interpulseinterval'
                    p.units = 's';
                case 'Nsteps'
                    p.displayTab = 'mostUsed';
                case 'waitForTrigger'
                    p.defaultValue = {'True', 'False'};
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@PulsedProtocol(obj);
            
            % Set amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'mV');
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'pA');
            end
            
            % Set pulse amplitude vector
            if ~obj.logScaling
                obj.AmpVec = linspace(obj.minPulseAmp, obj.maxPulseAmp, obj.Nsteps);
            else
                obj.AmpVec = logspace(log10(obj.minPulseAmp), log10(obj.maxPulseAmp), obj.Nsteps);
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
      
        function stimuli = sampleStimuli(obj)
            % Return a sample stimulus for display in the edit parameters window.
            stimuli{1} = obj.ampStimulus();
        end
        
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@PulsedProtocol(obj, epoch);
            
             % Randomize amplitudes if this is a new set
            if mod(obj.numEpochsQueued, obj.Nsteps) == 0
               obj.AmpVec = obj.AmpVec(randperm(obj.Nsteps)); 
            end
            
             % compute current amplitude and add parameter for it
            ampInd = mod(obj.numEpochsQueued, obj.Nsteps) + 1;
            
            %get current amplitude
            obj.curAmp = obj.AmpVec(ampInd);
            epoch.addParameter('curPulseAmp', obj.curAmp );
            
            % Add the amp pulse stimulus to the epoch.
            epoch.addStimulus(obj.amp, obj.ampStimulus());  
            
            if (strcmpi(obj.waitForTrigger,'true') == 1)
                epoch.waitForTrigger = false;
            else
                epoch.waitForTrigger = true;
            end
        end
        
        function stim = ampStimulus(obj)
            % Construct a pulse stimulus generator.
            p = PulseGenerator();
            
            % Assign generator properties.
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = obj.curAmp;
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
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
    end
    
end