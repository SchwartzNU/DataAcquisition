classdef SplitField < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.SplitField'
        version = 1
        displayName = 'Split Field'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        tailTime = 1000; %will be rounded to account for frame rate
        stimTime = 1000;
        
        intensity = 0.1

        Npositions = 2;
        barSeparation = 20; %microns
        
        Nangles = 2;
        barWidth = 1500; %microns
        barLength = 3000; %microns
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Hidden)
       curPosX
       curPosY   
       curStep
       curAngle
       stepList
       blackSideList
       angleList
       curBlackSide %0 = negative position side, 1 = positive position side
    end
    
    properties (Dependent)
        Nconditions
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case {'barSeparation', 'barWidth', 'barLength'}
                    p.units = 'um';   
                    p.displayTab = 'mostUsed';                
                case {'Npositions', 'Nangles', 'Nconditions'}
                    p.displayTab = 'mostUsed';                    
            end
        end
        
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set positions
            pixelStep = round(obj.barSeparation / obj.rigConfig.micronsPerPixel);           
            firstStep =  -floor(obj.Npositions/2) * pixelStep;          
            steps = firstStep:pixelStep:firstStep+(obj.Npositions-1)*pixelStep;  
            %these are the step distances from center
            
            %set angles
            angles = round(0:180/obj.Nangles:179); %degrees
            
            %make the list of positions and angles and randomize
            cycles = ceil(double(obj.numberOfAverages) / obj.Nconditions);
            z = 1;
            for i=1:cycles
                R = randperm(obj.Nconditions);
                for j=1:obj.Nconditions
                    stepList_temp(z) = steps(rem(R(j), obj.Npositions) + 1);
                    angleList_temp(z) = angles(rem(R(j), obj.Nangles) + 1);
                    blackSideList_temp(z) = R(j)<obj.Nconditions/2;
                    z=z+1;
                end
            end
                        
            obj.stepList = stepList_temp(1:obj.numberOfAverages);
            obj.angleList = angleList_temp(1:obj.numberOfAverages);
            obj.blackSideList = blackSideList_temp(1:obj.numberOfAverages);
                        
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'barAngle', 'barStep'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);   
                    %if testing only barAngle for OS, do 1D response
                    if obj.Npositions == 1
                        obj.openFigure('1D Response', obj.amp, 'EpochParam', 'barAngle', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, 'Mode', 'Whole cell');
                    elseif obj.Nangles == 1
                       obj.openFigure('1D Response', obj.amp, 'EpochParam', 'positionX', ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, 'Mode', 'Whole cell');
                    end
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {'barAngle', 'barStep'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                        %if testing only barAngle for OS, do 1D response
                        if obj.Npositions == 1
                            obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'barAngle', ...
                                'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                                'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, 'Mode', 'Whole cell');
                        elseif obj.Nangles == 1
                          obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'positionX', ...
                                'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                                'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, 'Mode', 'Whole cell');
                        end
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'barAngle', 'barStep'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    %if testing only barAngle for OS, do 1D response
                    if obj.Npositions == 1
                        obj.openFigure('1D Response', obj.amp, 'EpochParam', 'barAngle', ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                            'ResponseType', 'Spike count', 'Mode', 'Cell attached');
                    elseif obj.Nangles == 1
                        obj.openFigure('1D Response', obj.amp, 'EpochParam', 'positionX', ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                            'ResponseType', 'Spike count', 'Mode', 'Cell attached');
                        
                    end
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'barAngle', 'barStep'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
                        if obj.Npositions == 1
                            obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'barAngle', ...
                                'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                                'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                                'ResponseType', 'Spike count', 'Mode', 'Cell attached', 'LineColor', 'r');
                            
                        elseif obj.Nangles == 1
                            obj.openFigure('1D Response', obj.amp2, 'EpochParam', 'positionX', ...
                                'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                                'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                                'ResponseType', 'Spike count', 'Mode', 'Cell attached', 'LineColor', 'r');
                        end
                    end
                end
            end
            
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.St
            prepareEpoch@StageProtocol(obj, epoch);
           
            %current step and angle
            obj.curStep = obj.stepList(obj.numEpochsQueued+1);
            obj.curAngle = obj.angleList(obj.numEpochsQueued+1);
            obj.curBlackSide = obj.blackSideList(obj.numEpochsQueued+1);

            %get current position
            Xstep = obj.curStep*cos(obj.curAngle*pi/180);
            Ystep = obj.curStep*sin(obj.curAngle*pi/180);
           
            obj.curPosX = round(obj.windowSize(1)/2 + Xstep);
            obj.curPosY = round(obj.windowSize(2)/2 + Ystep);
            
            epoch.addParameter('positionX', obj.rigConfig.micronsPerPixel * (obj.curPosX - obj.windowSize(1)/2)); %in microns offset from center
            epoch.addParameter('positionY', obj.rigConfig.micronsPerPixel * (obj.curPosY - obj.windowSize(2)/2)); %in microns offset from center   
            epoch.addParameter('barAngle', obj.curAngle);
            epoch.addParameter('barStep', obj.curStep);
            epoch.addParameter('blackSide', obj.curBlackSide);
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            rect1 = Rectangle();
            rect1.size = [obj.barWidth/obj.rigConfig.micronsPerPixel, obj.barLength/obj.rigConfig.micronsPerPixel];            
            rect1.position = [obj.curPosX, obj.curPosY] - [obj.barWidth/(2*obj.rigConfig.micronsPerPixel)*cos(obj.curAngle*pi/180),obj.barWidth/(2*obj.rigConfig.micronsPerPixel)*sin(obj.curAngle*pi/180)];
            rect1.orientation = obj.curAngle;
            presentation.addStimulus(rect1);
            
            rect2 = Rectangle();
            rect2.size = [obj.barWidth/obj.rigConfig.micronsPerPixel, obj.barLength/obj.rigConfig.micronsPerPixel];            
            rect2.position = [obj.curPosX, obj.curPosY] + [obj.barWidth/(2*obj.rigConfig.micronsPerPixel)*cos(obj.curAngle*pi/180),obj.barWidth/(2*obj.rigConfig.micronsPerPixel)*sin(obj.curAngle*pi/180)];
            rect2.orientation = obj.curAngle;
            presentation.addStimulus(rect2);
            
            function c = onDuringStimPOS(state, preTime, stimTime, intensity, meanLevel)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    c = intensity;
                else
                    c = meanLevel;
                end
            end
            
            function c = onDuringStimNEG(state, preTime, stimTime, intensity, meanLevel)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    c = 2*meanLevel - intensity;
                else
                    c = meanLevel;
                end
            end
            
            if obj.curBlackSide
                controller1 = PropertyController(rect2, 'color', @(s)onDuringStimPOS(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
                controller2 = PropertyController(rect1, 'color', @(s)onDuringStimNEG(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
            else
                controller1 = PropertyController(rect1, 'color', @(s)onDuringStimPOS(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
                controller2 = PropertyController(rect2, 'color', @(s)onDuringStimNEG(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
            end
            
            presentation.addController(controller1);    
            presentation.addController(controller2);    

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
  
        function Nconditions = get.Nconditions(obj)
            Nconditions = obj.Nangles*obj.Npositions*2; %2 is for black and white side flip
        end       

    end
    
end