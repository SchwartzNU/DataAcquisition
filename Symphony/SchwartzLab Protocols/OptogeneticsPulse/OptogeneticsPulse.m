classdef OptogeneticsPulse < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.OptogeneticsPulse'
        version = 1
        displayName = 'Optogenetics Pulse'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 10 %ms 
        tailTime = 500 %will be rounded to account for frame rate
        
        %current to LED controller
        LED_intensity = 1; %units? 
        
        %point being stimulated
        stimPointX
        stimPointY
        
        stimNote = ' ';
    end
    
    properties
        numberOfAverages = uint16(10)
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
                case 'LED_intensity'
                    p.displayTab = 'mostUsed';
                    p.units = 'V (0.45 to 5)';
                case {'stimPointX', 'stimPointY', 'preTime', 'stimTime', 'stimNote', 'tailTime'}
                    p.displayTab = 'mostUsed';   
            end
        end
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
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
                    obj.openFigure('PSTH', obj.amp, ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                         'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                         'LineColor', 'r');
                    end
                end
            end
        end
        
         function prepareEpoch(obj, epoch)            
            prepareEpoch@StageProtocol(obj, epoch);
            
            % Set the epoch default background values for each device.
            devices = obj.rigConfig.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                % Set the default epoch background to be the same as the device background.
                if ~isempty(device.OutputSampleRate)
                    epoch.setBackground(char(device.Name), device.Background.Quantity, device.Background.DisplayUnit);
                end
            end
            
            % Add a stimulus trigger to pulse the blue LED
            if ~isempty(obj.rigConfig.deviceWithName('Optogenetics_LED'))
                disp('Making optogenetics stim');
                p = PulseGenerator();
                
                p.preTime = obj.preTime;
                p.stimTime = obj.stimTime;
                p.tailTime = obj.tailTime;
                p.amplitude = 1;
                p.mean = 0;
                p.sampleRate = obj.sampleRate;
                p.units = Symphony.Core.Measurement.UNITLESS;
                
                epoch.addStimulus('Optogenetics_LED', p.generate());
            end
            
            % Add the amplitude value to pulse the blue LED (start
            % amplitude during preTime to avoid a timing issue)
            if ~isempty(obj.rigConfig.deviceWithName('Optogenetics_LED_current'))
                disp('Making optogenetics stim');
                p = PulseGenerator();
                
                p.preTime = 0;
                p.stimTime = obj.stimTime + obj.preTime;
                p.tailTime = obj.tailTime;
                p.amplitude = obj.LED_intensity;
                p.mean = 0;
                p.sampleRate = obj.sampleRate;
                p.units = 'V';
                
                epoch.addStimulus('Optogenetics_LED_current', p.generate());
            end
            
            %for this stimulus, don't wait for trigger from photodiode
            epoch.waitForTrigger = false;
            
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
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