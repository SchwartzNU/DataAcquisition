classdef WhiteNoiseCurrentOrVoltage < PulsedProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.WhiteNoiseCurrentOrVoltage'
        version = 1
        displayName = 'White Noise Current or Voltage'
    end
    
    properties
        amp
        ampHoldSignal = 0
        amp2HoldSignal = 0
        preTime = 1000 
        stimTime = 8000
        tailTime = 1000
        noiseSD = 10 %mV or pA
        filterFreq = 30; %low pass filter (Hz)
        stimMode %rand, repeated, or alternating
        
        trigger = 'yes';
        
        numberOfAverages = uint16(5)
        interpulseInterval = 0
    end
    
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties (Hidden)
       curSeed = 1;
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case {'noiseSD', 'ampHoldSignal','amp2HoldSignal'}
                    p.units = 'mV or pA';
                    p.displayTab = 'mostUsed';
                case 'filterFreq'
                    p.units = 'Hz';
                    p.displayTab = 'mostUsed';
                case 'stimMode'
                    p.defaultValue = {'alternating','random', 'repeated'};
                    p.displayTab = 'mostUsed';
                case 'trigger'
                     p.defaultValue = {'no', 'yes'};
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
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'pA');
            end
            
            % Open figures for single trial responses of both amps
            obj.openFigure('Response', obj.amp);
            if ~isempty(obj.amp2)
                 obj.openFigure('Response', obj.amp2, 'LineColor', 'r');
            end
            
            % Open figures showing the mean response of the amp.
            obj.openFigure('Mean Response', obj.amp, 'GroupByParams', 'seedIsRepeated');
            if ~isempty(obj.amp2)
                if strcmp(obj.amp2Mode, 'Whole cell') 
                    obj.openFigure('Mean Response', obj.amp2, 'LineColor', 'r', 'GroupByParams', 'seedIsRepeated'); 
                elseif strcmp(obj.amp2Mode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                end
            end
        end
        
        
        function stim = noiseStimulus(obj, seed)
            % Construct a pulse stimulus generator.
            p = WaveformGenerator();
            
            %set rand seed
            rng(seed);
            
            scaleFactor = obj.sampleRate / 1E3; %ms to samples
            waveVec = ones(1, (obj.preTime + obj.stimTime + obj.tailTime) * scaleFactor) .* obj.ampHoldSignal;
            stimPart =  LowPassFilter(randn(1, obj.stimTime*scaleFactor), obj.filterFreq, 1/obj.sampleRate);
            stimPart = obj.ampHoldSignal + obj.noiseSD * stimPart/std(stimPart);
            waveVec(obj.preTime*scaleFactor+1:(obj.preTime+obj.stimTime)*scaleFactor) = stimPart;
                        
            % Assign generator properties.
            p.sampleRate = obj.sampleRate;
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                p.units = 'mV';
            else
                p.units = 'pA';
            end
            p.waveshape = waveVec;
            
            % Generate the stimulus object.
            stim = p.generate();
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            if strcmp(obj.stimMode, 'repeated')
                obj.curSeed = 1;
            elseif strcmp(obj.stimMode, 'random')
                obj.curSeed = randi(10000);
            else %alternating
                if mod(obj.numEpochsQueued, 2)
                    obj.curSeed = 1;
                else
                    obj.curSeed = randi(10000);
                end
            end
                
            %add seed parameter
            epoch.addParameter('randSeed', obj.curSeed);
            if obj.curSeed == 1
                epoch.addParameter('seedIsRepeated', 1);
            else
                epoch.addParameter('seedIsRepeated', 0);
            end
                
            % Add the amp pulse stimulus to the epoch.
            epoch.addStimulus(obj.amp, obj.noiseStimulus(obj.curSeed));  
            
            if strcmp(obj.trigger, 'yes')
                epoch.waitForTrigger = true;
            else
                epoch.waitForTrigger = false;
            end
            
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