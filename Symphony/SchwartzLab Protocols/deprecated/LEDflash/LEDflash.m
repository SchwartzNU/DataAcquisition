classdef LEDflash < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.LEDflash'
        version = 1
        displayName = 'LED Flash'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 10 %ms 
        tailTime = 500 %will be rounded to account for frame rate
        
        %intensity 0 to 1
        UV_LED_intensity = 0;
        GREEN_LED_intensity = 0;
    end
    
    properties
        numberOfAverages = uint16(10)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Dependent)
       flashRstar
       flashSstar
       flashMstar
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case {'UV_LED_intensity', 'GREEN_LED_intensity'}
                    p.displayTab = 'mostUsed';
                    p.units = 'norm. (0-1)';
                case {'preTime', 'stimTime', 'tailTime'}
                    p.displayTab = 'mostUsed';  
                case {'flashRstar', 'flashSstar', 'flashMstar'}
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

            %make UV LED stim
            if ~isempty(obj.rigConfig.deviceWithName('UV_LED'))
                disp('Making UV LED stim');
                if obj.UV_LED_intensity < 0 || obj.UV_LED_intensity > 1
                    disp('Error: UV intensity must be between 0 and 1');
                    return;
                end
                
                if obj.UV_LED_intensity == 0
                    voltageIntensity = 0;
                else
                    diffVals = abs(obj.rigConfig.uvLED_gamma - obj.UV_LED_intensity);
                    [~, minLoc] = min(diffVals);
                    minLoc = minLoc(1);
                    voltageIntensity = obj.rigConfig.gamma_X(minLoc)
                end
                
                p = PulseGenerator();
                
                p.preTime = obj.preTime;
                p.stimTime = obj.stimTime;
                p.tailTime = obj.tailTime;
                p.amplitude = voltageIntensity;
                p.mean = 0;
                p.sampleRate = obj.sampleRate;
                p.units = 'V';
                
                epoch.addStimulus('UV_LED', p.generate());
            end
            
            %make GREEN LED stim
            if ~isempty(obj.rigConfig.deviceWithName('GREEN_LED'))
                disp('Making GREEN LED stim');
                if obj.GREEN_LED_intensity < 0 || obj.GREEN_LED_intensity > 1
                    disp('Error: GREEN intensity must be between 0 and 1');
                    return;
                end
                
                if obj.GREEN_LED_intensity == 0
                    voltageIntensity = 0;
                else
                    diffVals = abs(obj.rigConfig.greenLED_gamma - obj.GREEN_LED_intensity);
                    [~, minLoc] = min(diffVals);
                    minLoc = minLoc(1);
                    voltageIntensity = obj.rigConfig.gamma_X(minLoc)
                end
                
                p = PulseGenerator();
                
                p.preTime = obj.preTime;
                p.stimTime = obj.stimTime;
                p.tailTime = obj.tailTime;
                p.amplitude = voltageIntensity;
                p.mean = 0;
                p.sampleRate = obj.sampleRate;
                p.units = 'V';
                
                epoch.addStimulus('GREEN_LED', p.generate());
            end
            
            %for this stimulus, don't wait for trigger from photodiode
            epoch.waitForTrigger = false;
            
         end
         
         function flashRstar = get.flashRstar(obj)
             factors(1) = obj.rigConfig.calib_UV; %uW at 0.1
             factors(2) = 1E-6; %uW to W
             factors(3) = obj.rigConfig.LED_area;
             factors(4) = obj.rigConfig.uv_Rod;
             factors(5) = 0.5; %rod area (square microns)
             uv_R = (factors(1)*factors(2)/factors(3))*factors(4)*factors(5)*obj.stimTime*1E-3;
             
             factors(1) = obj.rigConfig.calib_GREEN; %uW at 0.1
             factors(2) = 1E-6; %uW to W
             factors(3) = obj.rigConfig.LED_area;
             factors(4) = obj.rigConfig.green_Rod;
             factors(5) = 0.5; %rod area (square microns)
             green_R = (factors(1)*factors(2)/factors(3))*factors(4)*factors(5)*obj.stimTime*1E-3;
             
             flashRstar = uv_R * obj.UV_LED_intensity + green_R * obj.GREEN_LED_intensity;
         end
         
         function flashSstar = get.flashSstar(obj)
             factors(1) = obj.rigConfig.calib_UV; %uW at 0.1
             factors(2) = 1E-6; %uW to W
             factors(3) = obj.rigConfig.LED_area;
             factors(4) = obj.rigConfig.uv_Scone;
             factors(5) = 0.37; %cone area (square microns)
             uv_S = (factors(1)*factors(2)/factors(3))*factors(4)*factors(5)*obj.stimTime*1E-3;
             
             factors(1) = obj.rigConfig.calib_GREEN; %uW at 0.1
             factors(2) = 1E-6; %uW to W
             factors(3) = obj.rigConfig.LED_area;
             factors(4) = obj.rigConfig.green_Scone;
             factors(5) = 0.37; %cone area (square microns)
             green_S = (factors(1)*factors(2)/factors(3))*factors(4)*factors(5)*obj.stimTime*1E-3;
             
             flashSstar = uv_S * obj.UV_LED_intensity + green_S * obj.GREEN_LED_intensity;
     
         end
         
         function flashMstar = get.flashMstar(obj)
             factors(1) = obj.rigConfig.calib_UV; %uW at 0.1
             factors(2) = 1E-6; %uW to W
             factors(3) = obj.rigConfig.LED_area;
             factors(4) = obj.rigConfig.uv_Mcone;
             factors(5) = 0.37; %cone area (square microns)
             uv_M = (factors(1)*factors(2)/factors(3))*factors(4)*factors(5)*obj.stimTime*1E-3;
             
             factors(1) = obj.rigConfig.calib_GREEN; %uW at 0.1
             factors(2) = 1E-6; %uW to W
             factors(3) = obj.rigConfig.LED_area;
             factors(4) = obj.rigConfig.green_Mcone;
             factors(5) = 0.37; %cone area (square microns)
             green_M = (factors(1)*factors(2)/factors(3))*factors(4)*factors(5)*obj.stimTime*1E-3;
             
             flashMstar = uv_M * obj.UV_LED_intensity + green_M * obj.GREEN_LED_intensity;
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