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
        
        temporalAlignment = 0;
        refineCenter = 0;
        
        numPresentations = 1;
                      
        valueMin = 0;
        valueMax = 1.0;
        numValues = 1;
        numValueRepeats = 1;
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
        sessionId
        epochNum
    end
    
    properties (Dependent)
        stimTime
        intensity
        values
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
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            obj.sessionId = randi(999999999);
            obj.epochNum = 0;
            
            obj.spatialFigure = obj.openFigure('Shape Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd,...
                'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
            
%             obj.openFigure('PSTH', obj.amp, ...
%                 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
%                 'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
            
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            
            % choose center position and search width
            center = [0,0];
            searchDiameterUpdated = obj.searchDiameter;
            if obj.refineCenter > 0
                if obj.epochNum > 0
                    center = obj.spatialFigure.outputData.centerOfMassXY;
                    searchDiameterUpdated = 2 * obj.spatialFigure.outputData.farthestResponseDistance + 1;
                end
            end
            
            % select positions
            positions = generatePositions('random', [obj.numSpots, obj.spotDiameter, searchDiameterUpdated / 2]);
%             positions = generatePositions('grid', [obj.searchDiameter, round(sqrt(obj.numSpots))]);

            % add center offset
            positions = bsxfun(@plus, positions, center);

            % generate intensity values and repeats
            obj.numSpots = size(positions,1); % in case the generatePositions function is imprecise
            values = linspace(obj.valueMin, obj.valueMax, obj.numValues);
            positionList = zeros(obj.numValues * obj.numSpots, 3);
            
            stream = RandStream('mt19937ar');
            si = 1; %spot index
            for repeat = 1:obj.numValueRepeats
                usedValues = zeros(obj.numSpots, obj.numValues);
                for l = 1:obj.numValues
                    positionIndexList = randperm(stream, obj.numSpots);
                    for i = 1:obj.numSpots
                        curPosition = positionIndexList(i);
                        possibleNextValueIndices = find(usedValues(curPosition,:) == 0);
                        nextValueIndex = possibleNextValueIndices(randi(stream, length(possibleNextValueIndices)));
                        
                        positionList(si,:) = [positions(curPosition,:), values(nextValueIndex)];
                        usedValues(curPosition, nextValueIndex) = 1;
                        
                        si = si + 1;
                    end
                end
            end
            
            obj.shapeData = positionList;
            obj.shapeDataColumns = {'X','Y','intensity'};
            
%             epoch.addParameter('positions', obj.positions(:));
            obj.epochNum = obj.epochNum + 1;
            epoch.addParameter('sessionId',obj.sessionId);
            epoch.addParameter('presentationId',obj.epochNum);
            epoch.addParameter('shapeData', obj.shapeData(:));
            epoch.addParameter('shapeDataColumns', strjoin(obj.shapeDataColumns,','));
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
                    shapeIndex = floor(t / totalTime) + 1;
                    t = t - (shapeIndex - 1) * totalTime; % use the same index as the position below
                    if t < onTime && shapeIndex <= size(intensity, 1)
                        c = intensity(shapeIndex,1);
                    else
                        c = meanLevel;
                    end
                else
                    c = meanLevel;
                end
            end
            
            col_int = find(not(cellfun('isempty', strfind(obj.shapeDataColumns, 'intensity'))));
            intensities = obj.shapeData(:,col_int);
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
            % add a bit to the end to make sure we get all the spots
            stimTime = round((obj.spotTotalTime * obj.numSpots * obj.numValues * obj.numValueRepeats + 1.0)* 1e3);
        end
        
        function values = get.values(obj)
            values = linspace(obj.valueMin, obj.valueMax, obj.numValues);
%             disp(mat2str(values))
            values = mat2str(values, 2);
        end
        
        function intensity = get.intensity(obj)
            intensity = obj.valueMax;
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
                keepQueuing = obj.numEpochsQueued < obj.numPresentations;
            end
        end
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@StageProtocol(obj);
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.numEpochsCompleted < obj.numPresentations;
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