classdef MovingBar < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.MovingBar'
        version = 2
        displayName = 'Moving Bar'
    end
    
    
    properties
        amp
        %times in ms
        preTime = 250 %will be rounded to account for frame rate
        tailTime = 250 %will be rounded to account for frame rate
        
        %in microns, use rigConfig to set microns per pixel
        barWidth = 50;
        barLength = 200;
        barSpeed = 1000; %um/s
        distance = 1500; %um

        Nangles = 8;
        intensity = 0.5;
        startAngle = 0;
    end
    
    properties (Dependent)
        stimTime
    end

    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
        
    properties (Hidden)
       curAngle
       angles 
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case 'barSpeed'
                    p.displayTab = 'mostUsed';
                    p.units = 'um/s';
                case {'barWidth', 'barLength', 'distance'}
                    p.units = 'um';
                    p.displayTab = 'mostUsed';
                case {'Nangles', 'startAngle'}
                    p.displayTab = 'mostUsed';
            end
        end
        

        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set directions
            obj.angles = rem(obj.startAngle:round(360/obj.Nangles):obj.startAngle+359, 360);
            
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'barAngle'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'barAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'PlotType', 'Polar');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {'barAngle'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'barAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                        'Mode', 'Whole cell', 'PlotType', 'Polar', 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'barAngle'}, ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', 'barAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                        'Mode', 'Cell attached', 'PlotType', 'Polar');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'barAngle'}, ...
                            'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                           'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'barAngle', ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'Mode', 'Cell attached', 'PlotType', 'Polar', ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                    end
                end
            end
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            % Randomize angles if this is a new set
            if mod(obj.numEpochsQueued, obj.Nangles) == 0
               obj.angles = obj.angles(randperm(obj.Nangles)); 
            end
            
            % compute current angle and add parameter to the epoch       
            angleInd = mod(obj.numEpochsQueued, obj.Nangles) + 1;
            
            obj.curAngle = obj.angles(angleInd); %make it a property so preparePresentation has access to it
            epoch.addParameter('barAngle', obj.curAngle);
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            rect = Rectangle();
            rect.color = obj.intensity;
            rect.orientation = obj.curAngle;
            rect.size = round([obj.barLength, obj.barWidth]./obj.rigConfig.micronsPerPixel);
            presentation.addStimulus(rect);
            pixelSpeed = obj.barSpeed./obj.rigConfig.micronsPerPixel;
            %disp(obj.curAngle)
            Xstep = cos(obj.curAngle*pi/180);
            Ystep = sin(obj.curAngle*pi/180);
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
        
        function stimTime = get.stimTime(obj)
            pixelSpeed = obj.barSpeed./obj.rigConfig.micronsPerPixel;
            pixelDistance = obj.distance./obj.rigConfig.micronsPerPixel;
            stimTime = round(1E3*pixelDistance/pixelSpeed);
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
            
        end

    end
    
end