classdef BarsMultiSpeed < StageProtocol
    %Adam 5/27/14, based on "MovingBar"
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.BarsMultiSpeed'
        version = 2 %8/7/2014
        displayName = 'Bars multiple speeds'
       
        %maxSpeed8bit = 5000;
    end
    
    properties
        amp
        %times in ms
        preTime = 250 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        %in microns, use rigConfig to set microns per pixel
        barWidth = 50;
        barLength = 200;
        %barSpeed = 1000; %um/s
        distance = 1500; %um

        %Nangles = 8;
        intensity = 0.5;
        %startAngle = 0;
        offsetAngle = 0;
        
        startSpeed = 1000;
        %finishSpeed = 5000;
        Nspeeds = 5;
        spacingFactor = 1.5;
        maxSpeed8bit = 2000;
        
        stimTime;
        
    end
    
    properties (Dependent)
        finishSpeed   %dependent, for logarithmic spacing speed axis;
        Nconditions
    end

    properties
        numberOfAverages = uint16(5)  %USER: choose multiple of Nconditions
        %interpule interval in s
        interpulseInterval = 0
    end
        
    properties (Hidden)
       curSpeed
       speeds
       epochSpeeds
       epochBitDepths
      
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case {'startSpeed', 'finishSpeed', 'Nspeeds','spacingFactor'};
                    p.displayTab = 'mostUsed';
                    p.units = 'um/s';
                case {'barWidth', 'barLength', 'distance'}
                    p.units = 'um';
                    p.displayTab = 'mostUsed';
                case {'offsetAngle', 'Nconditions'}
                    p.displayTab = 'mostUsed';
            end
        end
        

        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set directions
            %obj.angles = rem(obj.startAngle:round(360/obj.Nangles):obj.startAngle+359, 360);
            
            %set speeds
            if obj.startSpeed == obj.finishSpeed
                obj.speeds = obj.startSpeed;
            else    
                %obj.speeds = obj.startSpeed:floor((obj.finishSpeed-obj.startSpeed)/(obj.Nspeeds-1)):obj.finishSpeed;
                obj.speeds = obj.startSpeed.*obj.spacingFactor.^(0:obj.Nspeeds-1);
            end;
            %Determine epochs parameter set
            epochsPerCond = floor(obj.numberOfAverages/obj.Nconditions);
            NAverages = epochsPerCond*obj.Nconditions;
            
            obj.epochBitDepths = zeros(NAverages,1);
            obj.epochSpeeds = zeros(NAverages,1);
            
            obj.epochBitDepths(1:length(obj.speeds)*epochsPerCond) = 8;         %for all speeds
            for batch = 1:epochsPerCond
                obj.epochSpeeds(obj.Nspeeds*(batch-1)+1:obj.Nspeeds*batch) = obj.speeds;  %for all speeds 
            end;
            
            %additional epochs with bitDepth 2 for speeds higher than MaxSpeed8bit
            NfastSpeeds = sum(obj.speeds > obj.maxSpeed8bit);
            obj.epochBitDepths(obj.Nspeeds*epochsPerCond+1:end) = 2; %WILL NOT ACCEPT 2?!
            for batch = 1:epochsPerCond
                obj.epochSpeeds(obj.Nspeeds*epochsPerCond + NfastSpeeds*(batch-1)+1:obj.Nspeeds*epochsPerCond + NfastSpeeds*batch)...
                    = obj.speeds(obj.speeds > obj.maxSpeed8bit);      
            end;
           
           
            
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'curSpeed', 'curBitDepth'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curSpeed', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {'curSpeed', 'curBitDepth'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'curSpeed', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'curSpeed', 'curBitDepth'}, ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curSpeed', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                        'Mode', 'Cell attached');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'curSpeed', 'curBitDepth'}, ...
                            'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                           'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'curSpeed', ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'Mode', 'Cell attached', ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                    end
                end
            end
        end
        
        function prepareEpoch(obj, epoch)
            disp('preparing epoch');

            %Set current speed
            %Set current bit depth. 
            epochInd = obj.numEpochsQueued+1; 
            if epochInd > length(obj.epochSpeeds)
                epochInd = 1; %If have spare epochs than just return to begining of condition list.
            end;    
            obj.curSpeed = obj.epochSpeeds(epochInd); %Set speed for curr. epoch
            obj.bitDepth = obj.epochBitDepths(epochInd); %Set bit depth.
            if obj.bitDepth == 2
                obj.patternsPerFrame = 12;                
            else
                obj.patternsPerFrame = 2;
            end
            obj.stimTime = obj.getStimTime();
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            %obj.RstarIntensity = obj.(get.RstarIntensity());
            %obj.RstarMean = obj.(get.RstarMean());

            %STORE speed, bitDepth
            epoch.addParameter('curSpeed', obj.curSpeed);
            epoch.addParameter('curBitDepth', obj.bitDepth);
            
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            rect = Rectangle();
            rect.color = obj.intensity;
            rect.orientation = obj.offsetAngle;
            rect.size = round([obj.barLength, obj.barWidth]./obj.rigConfig.micronsPerPixel);
            presentation.addStimulus(rect);
            obj.bitDepth
            obj.patternRate
            obj.patternsPerFrame
            obj.RstarIntensity
            pixelSpeed = obj.curSpeed./obj.rigConfig.micronsPerPixel;
            %disp(obj.curAngle)
            Xstep = cos(obj.offsetAngle*pi/180);
            Ystep = sin(obj.offsetAngle*pi/180);
            %disp(Xstep)
            %disp(Ystep)
            Xpos = obj.windowSize(1)/2 - Xstep*obj.windowSize(2)/2;
            Ypos = obj.windowSize(2)/2 - Ystep*obj.windowSize(2)/2;
            %disp(Xpos)
            %disp(Ypos)
            
            function pos = movementController(state, duration, preTime, tailTime, Xpos, Ypos, Xstep, Ystep, pixelSpeed)
                if state.time<=preTime/1E3 || state.time>duration-tailTime/1E3
                    %off screen
                    pos = [NaN, NaN];
                else
                    pos = [Xpos+(state.time-preTime/1E3)*pixelSpeed*Xstep, Ypos+(state.time-preTime/1E3)*pixelSpeed*Ystep];  
                end
            end
            controller = PropertyController(rect, 'position', @(s)movementController(s, presentation.duration, obj.preTime, obj.tailTime, Xpos, Ypos, Xstep, Ystep, pixelSpeed));            
            presentation.addController(controller);             
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
        
        function finishSpeed = get.finishSpeed(obj)
            %dependent, for logarithmic spacing speed axis;
            finishSpeed = obj.startSpeed.*obj.spacingFactor^(obj.Nspeeds-1);
        end
        
        function stimTime = getStimTime(obj)
            if isempty(obj.curSpeed)
                obj.curSpeed = obj.startSpeed;
            end;    
            pixelSpeed = obj.curSpeed./obj.rigConfig.micronsPerPixel;
            pixelDistance = obj.distance./obj.rigConfig.micronsPerPixel;
            stimTime = round(1E3*pixelDistance/pixelSpeed) + obj.tailTime;
        end
        
        function Nconditions = get.Nconditions(obj)
           
            %set speeds
            if obj.startSpeed == obj.finishSpeed
                tempObjSpeeds = obj.startSpeed;
            else    
                %tempObjSpeeds = obj.startSpeed:floor((obj.finishSpeed-obj.startSpeed)/(obj.Nspeeds-1)):obj.finishSpeed;
                tempObjSpeeds = obj.startSpeed.*obj.spacingFactor.^(0:obj.Nspeeds-1);
            end; 
           %^ugly. It's because obj.speeds hasn't been determined yet.
           
           slowSpeeds = sum(tempObjSpeeds <= obj.maxSpeed8bit);
           fastSpeeds = sum(tempObjSpeeds > obj.maxSpeed8bit);
           Nconditions = slowSpeeds + fastSpeeds*2;
        end    
            
        function pn = parameterNames(obj, includeConstant)
            if nargin == 1
                pn = parameterNames@StageProtocol(obj);
            else
                pn = parameterNames@StageProtocol(obj, includeConstant);
            end
            
            % hide params
            pn = pn(~strcmp(pn, 'preTime'));
            pn = pn(~strcmp(pn, 'tailTime'));
            pn = pn(~strcmp(pn, 'bitDepth'));
            pn = pn(~strcmp(pn, 'patternsPerFrame'));

        end
    end
    
end