classdef AutoCenter < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.AutoCenter'
        version = 3
        displayName = 'Auto Center'
    end
    
    properties
        amp
        %times in ms
        preTime = 250 %will be rounded to account for frame rate
        tailTime = 250 %will be rounded to account for frame rate
        
        %in microns, use rigConfig to set microns per pixel
        spotDiameter = 50; %um
        searchDiameter = 200; %um
        numSpots = 30;
        spotTotalTime = 0.5;
        spotOnTime = 0.1;
        
        responseDelay = 50; %ms
        
        intensity = 1.0;
    end
    
    properties
        %interpulse interval in s
        interpulseInterval = 0;
    end
    
    
    properties (Hidden)
        spatialFigure
%         positions
        shapeData
        shapeDataColumns
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
                case {'spotTotalTime','spotOnTime'}
                    p.units = 's';
                    p.displayTab = 'mostUsed';
                case {'startX', 'startY', 'spotDiameter','searchDiameter'}
                    p.units = 'um';
                    p.displayTab = 'mostUsed';
                case 'numSpots'
                    p.displayTab = 'mostUsed';
                case 'intensity'
                    p.displayTab = 'mostUsed';
                    p.units = 'rel';
                case 'responseDelay'
                    p.units = 'msec';
            end
        end
        
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set positions
            positions = generatePositions('random',[obj.numSpots, obj.spotDiameter, obj.searchDiameter]);
            
            obj.shapeData = horzcat(positions, obj.intensity * ones(obj.numSpots, 1));
            obj.shapeDataColumns = {'X','Y','intensity'};
            
            obj.spatialFigure = obj.openFigure('Spatial Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd,...
                'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
            
%             obj.openFigure('PSTH', obj.amp, ...
%                 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
%                 'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
            
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
%             epoch.addParameter('positions', obj.positions(:));
            epoch.addParameter('shapeData', obj.shapeData(:));
            epoch.addParameter('shapeDataColumns', obj.shapeDataColumns);
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            circ = Ellipse();
            circ.color = obj.intensity;
            circ.radiusX = round(obj.spotDiameter/2/obj.rigConfig.micronsPerPixel);
            circ.radiusY = circ.radiusX;
            circ.position = [0,0];
            presentation.addStimulus(circ);
            
            function c = shapeColor(state, totalTime, onTime, preTime, stimTime, intensity, meanLevel)
                if state.time > preTime*1e-3 && state.time <= (preTime+stimTime)*1e-3
                    t = state.time - preTime * 1e-3;
                    m = floor(t / totalTime);
                    t = t - m * totalTime; % use the same index as the position below
                    shapeIndex = m + 1;
                    if t < onTime
                        c = intensity(shapeIndex);
                    else
                        c = meanLevel;
                    end
                else
                    c = meanLevel;
                end
            end
            
            
            icol = find(not(cellfun('isempty', strfind(obj.shapeDataColumns, 'intensity'))));
            intensities = obj.shapeData(:,icol);
            controllerColor = PropertyController(circ, 'color', @(s)shapeColor(s, obj.spotTotalTime, obj.spotOnTime, obj.preTime, obj.stimTime, intensities, obj.meanLevel));
            presentation.addController(controllerColor);
            
            
            function p = shapePosition(state, pos, totalTime, preTime, stimTime, windowSize, micronsPerPixel)
                if state.time < preTime*1e-3 || state.time >= (preTime+stimTime)*1e-3
                    p = [NaN, NaN];
%                     p = [0,0];
                else                  
                    t = state.time - preTime * 1e-3;
                    shapeIndex = floor(t / totalTime) + 1;
                    if shapeIndex <= size(pos,1)
                        p = [pos(shapeIndex,1)/micronsPerPixel + windowSize(1)/2, pos(shapeIndex,2)/micronsPerPixel + windowSize(2)/2];
                    else
                        p = [NaN, NaN];
%                         p = [0,0];
                    end
                end
            end
            mpp = obj.rigConfig.micronsPerPixel;
            
            xcol = find(not(cellfun('isempty', strfind(obj.shapeDataColumns, 'X'))));
            ycol = find(not(cellfun('isempty', strfind(obj.shapeDataColumns, 'Y'))));
            positions = obj.shapeData(:,[xcol,ycol]);
            
            controllerPosition = PropertyController(circ, 'position', @(s)shapePosition(s, positions, ...
                obj.spotTotalTime, obj.preTime, obj.stimTime, obj.windowSize, mpp));
            
            presentation.addController(controllerPosition);
            
            preparePresentation@StageProtocol(obj, presentation);
        end
        
        
        function stimTime = get.stimTime(obj)
            stimTime = round(obj.spotTotalTime * obj.numSpots * 1e3);
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
                keepQueuing = obj.numEpochsQueued < 1;
            end
        end
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@StageProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < 1;
            end
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