classdef VoltagePulseAndLightStep < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.VoltagePulseAndLightStep'
        version = 1
        displayName = 'Voltage Pulse and Light Step'
    end
    
    properties
        amp
        preTime = 500 
        stimTime = 500
        tailTime = 500
        pulseDelay = 100 %ms
        pulseAmplitude = 60 %mV or pA
        
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
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case {'pulseAmplitude', 'ampHoldSignal','amp2HoldSignal'}
                    p.units = 'mV or pA';
                    p.displayTab = 'mostUsed';
                case {'ampMode', 'amp2Mode'}
                    p.defaultValue = {'Whole cell', 'Cell attached'};
                case 'spotSize'
                    p.displayTab = 'mostUsed';
                    p.units = 'um';
                case 'pulseDelay'
                    p.displayTab = 'mostUsed';
                    p.units = 'ms';
                case 'interpulseInterval'
                    p.units = 's';
                case 'numberOfAverages'
                    p.displayTab = 'mostUsed';
                case {'intensity', 'meanLevel'}
                    p.displayTab = 'mostUsed';
                    p.units = 'rel';
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
            
            controller = PropertyController(spot, 'color', @(s)onDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
            presentation.addController(controller);
            
            preparePresentation@StageProtocol(obj, presentation);            
        end
        
        function prepareRun(obj)
           global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);

            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'pulseDelivered'}, ...
                    'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {'pulseDelivered'}, ...
                    'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
            end
            
            % Set amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'mV');
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'pA');
            end            
        end
        
        
        function stim = ampStimulus(obj)
            % Construct a pulse stimulus generator.
            p = PulseGenerator();
            
            % Assign generator properties.
            p.preTime = obj.preTime + obj.pulseDelay;
            p.stimTime = obj.stimTime;
            p.tailTime = obj.tailTime - obj.pulseDelay;
            if mod(obj.numEpochsQueued, 2) == 1 %pulse every other epoch
                p.amplitude = obj.pulseAmplitude;
            else
                p.amplitude = 0;
            end
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
            stimuli{1} = obj.ampStimulus();
        end
        
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            %add parameter for whether pulse was delivered
            if mod(obj.numEpochsQueued, 2) == 1 %pulse every other epoch
                epoch.addParameter('pulseDelivered', 1);
            else
                epoch.addParameter('pulseDelivered', 0);
            end
            % Add the amp pulse stimulus to the epoch.
            epoch.addStimulus(obj.amp, obj.ampStimulus());  
        end
        
        
        function queueEpoch(obj, epoch)            
            % Call the base method to queue the actual epoch.
            queueEpoch@StageProtocol(obj, epoch);
            
            % Queue an inter-pulse interval after queuing the epoch.
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