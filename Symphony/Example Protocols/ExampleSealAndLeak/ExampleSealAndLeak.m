classdef ExampleSealAndLeak < SymphonyProtocol
    
    properties (Constant)
        identifier = 'io.github.symphony-das.ExampleSealAndLeak'
        version = 1
        displayName = 'Example Seal and Leak'
    end
    
    properties
        amp
        mode = {'seal', 'leak'}
        alternateMode = true
        preTime = 15
        stimTime = 30
        tailTime = 15
        pulseAmplitude = 5
        leakAmpHoldSignal = -60
    end
    
    properties (Hidden, Dependent, SetAccess = private)
        ampHoldSignal
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
                case 'alternateMode'
                    p.description = 'Alternate from seal to leak to seal etc., on each successive run.';
                case {'preTime', 'stimTime', 'tailTime'}
                    p.units = 'ms';
                case {'pulseAmplitude', 'leakAmpHoldSignal'}
                    p.units = 'mV or pA';
            end
        end
        
        
        function s = get.ampHoldSignal(obj)
            if strcmpi(obj.mode, 'seal')
                s = 0;
            else
                s = obj.leakAmpHoldSignal;
            end
        end
        
        
        function init(obj, rigConfig)
            % Call the base method.
            init@SymphonyProtocol(obj, rigConfig);
            
            % Epochs of indefinite duration, like those produced by this protocol, cannot be saved. 
            obj.allowSavingEpochs = false;
            obj.allowPausing = false;            
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
        end
        
        
        function stim = ampStimulus(obj)
            % Construct a repeating pulse stimulus generator.
            p = RepeatingPulseGenerator();
            
            % Assign generator properties.
            p.preTime = obj.preTime;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime;
            p.amplitude = obj.pulseAmplitude;
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
            % We cannot display a stimulus with an infinite number of pulses. Instead we will display a single pulse 
            % generated with the same parameters used to generate the repeating pulse stimulus.
            stim = obj.ampStimulus();
            
            params = dictionaryToStruct(stim.Parameters);
            params = rmfield(params, {'version', 'generatorClassName'});
            
            p = PulseGenerator(params);
            stimuli{1} = p.generate();
        end
        
        
        function prepareEpoch(obj, epoch)            
            % With an indefinite epoch protocol we should not call the base class.
            %prepareEpoch@SymphonyProtocol(obj, epoch);
            
            % Set the epoch default background values for each device.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                % Set the default epoch background to be the same as the device background.
                if ~isempty(device.OutputSampleRate)
                    epoch.setBackground(char(device.Name), device.Background.Quantity, device.Background.DisplayUnit);
                end
            end
            
            % Add a stimulus to trigger an oscilliscope at the start of each pulse.
            if ~isempty(obj.rigConfig.deviceWithName('Oscilloscope_Trigger'))
                p = RepeatingPulseGenerator();
                
                p.preTime = 0;
                p.stimTime = 1;
                p.tailTime = obj.preTime + obj.stimTime + obj.tailTime - 1;
                p.amplitude = 1;
                p.mean = 0;
                p.sampleRate = obj.sampleRate;
                p.units = Symphony.Core.Measurement.UNITLESS;
                
                epoch.addStimulus('Oscilloscope_Trigger', p.generate());
            end
            
            % Add the amp pulse stimulus to the epoch.
            epoch.addStimulus(obj.amp, obj.ampStimulus());
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepQueuing = continueQueuing@SymphonyProtocol(obj);
            
            % Queue only one indefinite epoch.
            if keepQueuing
                keepQueuing = obj.numEpochsQueued < 1;
            end            
        end
        
        
        function completeRun(obj)
            % Call the base method.
            completeRun@SymphonyProtocol(obj);
            
            if obj.alternateMode
                if strcmpi(obj.mode, 'seal')
                    obj.mode = 'leak';
                else
                    obj.mode = 'seal';
                end
            end
        end
        
    end
    
end