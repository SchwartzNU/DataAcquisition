classdef ReceptiveField1D < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.ReceptiveField1D'
        version = 2
        displayName = 'Receptive Field 1D'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        contrast = 0.5
        frequency = 4; %hz
        
        probeAxis
        Npositions = 9;
        barSeparation = 40; %microns
        barWidth = 40; %microns
        barLength = 300; %microns
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Hidden)
       curPosX
       curPosY
       positions 
    end
    
    properties (Dependent)
        stimTime
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
                case 'frequency'
                    p.units = 'Hz';
                case 'probeAxis'
                    p.defaultValue = {'horizontal', 'vertical'};
                    p.displayTab = 'mostUsed';
                case 'meanLevel'
                    p.defaultValue = 0.5;
                case 'Npositions'
                    p.displayTab = 'mostUsed';
            end
        end
        
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set positions
            pixelStep = round(obj.barSeparation / obj.rigConfig.micronsPerPixel);            
            if strcmp(obj.probeAxis, 'horizontal')
                firstPos = round(obj.windowSize(1)/2) - floor(obj.Npositions/2) * pixelStep;
                posStr = 'positionX';
            else
                firstPos = round(obj.windowSize(2)/2) - floor(obj.Npositions/2) * pixelStep;                 
                posStr = 'positionY';
            end
            obj.positions = firstPos:pixelStep:firstPos+(obj.Npositions-1)*pixelStep;
            
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {posStr}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);                    
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', posStr, ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'LineStyle', '-', ...
                        'ResponseType', 'CycleAvgF1', 'Mode', 'Whole cell');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {posStr}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', posStr, ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'LineStyle', '-', ...
                            'ResponseType', 'CycleAvgF1', 'Mode', 'Whole cell', 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {posStr}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                    obj.openFigure('1D Response', obj.amp, 'EpochParam', posStr, ...
                        'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                        'LineStyle', '-', ...
                        'ResponseType', 'CycleAvgF1', 'Mode', 'Cell attached');
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {posStr}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...   
                            'LineColor', 'r');
                        obj.openFigure('1D Response', obj.amp2, 'EpochParam', posStr, ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineStyle', '-', ...
                            'ResponseType', 'CycleAvgF1', 'Mode', 'Cell attached', 'LineColor', 'r');
                    end
                end
            end
            
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.St
            prepareEpoch@StageProtocol(obj, epoch);
            
            % compute current position and add parameters to the epoch       
            positionInd = mod(obj.numEpochsQueued, obj.Npositions) + 1;
            
            %get current position
            if strcmp(obj.probeAxis, 'horizontal')
                obj.curPosX = obj.positions(positionInd);
                obj.curPosY = obj.windowSize(2)/2;
            else
                obj.curPosX = obj.windowSize(1)/2;
                obj.curPosY = obj.positions(positionInd);
            end
            epoch.addParameter('positionX', obj.rigConfig.micronsPerPixel * (obj.curPosX - obj.windowSize(1)/2));
            epoch.addParameter('positionY', obj.rigConfig.micronsPerPixel * (obj.curPosY - obj.windowSize(2)/2));            
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            rect = Rectangle();
            if strcmp(obj.probeAxis, 'horizontal')
                rect.size = [obj.barWidth/obj.rigConfig.micronsPerPixel, obj.barLength/obj.rigConfig.micronsPerPixel];
            else
                rect.size = [obj.barLength/obj.rigConfig.micronsPerPixel, obj.barWidth/obj.rigConfig.micronsPerPixel];
            end            
            rect.position = [obj.curPosX, obj.curPosY];
            presentation.addStimulus(rect);
            
            function c = sineWaveStim(state, preTime, stimTime, contrast, meanLevel, freq)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    timeVal = state.time - preTime*1e-3; %s
                    %inelegant solution for zero mean
                    if meanLevel < 0.05
                        c = contrast * sin(2*pi*timeVal*freq);
                        if c<0, c = 0; end %rectify
                    else
                        c = meanLevel + meanLevel * contrast * sin(2*pi*timeVal*freq);
                    end
                else
                    c = meanLevel;
                end
            end
            
            controller = PropertyController(rect, 'color', @(s)sineWaveStim(s, obj.preTime, obj.stimTime, obj.contrast, obj.meanLevel, obj.frequency));
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
            %4 cycles
            stimTime = 1E3*(4/obj.frequency); %ms
        end

    end
    
end