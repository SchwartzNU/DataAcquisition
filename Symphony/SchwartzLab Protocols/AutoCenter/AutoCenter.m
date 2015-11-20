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
        spotDiameter = 30; %um
        searchDiameter = 250; %um
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
        shapeDataMatrix
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
            
            
            obj.sessionId = regexprep(num2str(fix(clock),'%1d'),' +',''); % this is how you get a datetime string in MATLAB
            obj.epochNum = 0;
            
            obj.spatialFigure = obj.openFigure('Shape Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd,...
                'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
            
%             obj.openFigure('PSTH', obj.amp, ...
%                 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
%                 'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
            
            prepareRun@StageProtocol(obj);

        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            obj.epochNum = obj.epochNum + 1;
            
            prepareEpoch@StageProtocol(obj, epoch);
            
            if obj.temporalAlignment > 0 && obj.epochNum == 1
                epochMode = 'temporalAlignment';
                durations = [1, 0.6, 0.4];
                numSpotsPerRate = obj.temporalAlignment;
                diam_ta = 100;
                obj.shapeDataMatrix = [];

                tim = 0;
                for dur = durations
                    for si = 1:numSpotsPerRate
                        shape = [0, 0, obj.valueMax, tim, tim + dur / 3, diam_ta];
                        obj.shapeDataMatrix = vertcat(obj.shapeDataMatrix, shape);
                        tim = tim + dur;
                    end
                end
%                 obj.stimTimeSaved = round(1000 * (1.0 + tim));
                obj.shapeDataColumns = {'X','Y','intensity','startTime','endTime','diameter'};
%                 disp(obj.shapeDataMatrix)
            
            else % standard search
                epochMode = 'flashingSpots';
                
                % choose center position and search width
                center = [0,0];
                searchDiameterUpdated = obj.searchDiameter;
                if obj.refineCenter > 0 && obj.epochNum > 0 && obj.spatialFigure.outputData.validSearchResult == 1
                    gfp = obj.spatialFigure.outputData.gaussianFitParams;
                    
                    center = [gfp('centerX'), gfp('centerY')];
                    searchDiameterUpdated = 3 * max([gfp('sigma2X'), gfp('sigma2Y')]) + 1;
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
                starts = zeros(obj.numSpots, 1);
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
                            
                            starts(si) = (si - 1) * obj.spotTotalTime;

                            si = si + 1;
                        end
                    end
                end
                diams = obj.spotDiameter * ones(length(starts), 1);
                ends = starts + obj.spotOnTime;
                
%                 obj.stimTimeSaved = round(1000 * (ends(end) + 1.0));
                
                obj.shapeDataMatrix = horzcat(positionList, starts, ends, diams);
                obj.shapeDataColumns = {'X','Y','intensity','startTime','endTime','diameter'};
            end
            
%             epoch.addParameter('positions', obj.positions(:));

            epoch.addParameter('sessionId',obj.sessionId);
            epoch.addParameter('presentationId',obj.epochNum);
            epoch.addParameter('epochMode',epochMode);
            epoch.addParameter('shapeDataMatrix', obj.shapeDataMatrix(:));
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
            
            
            % GENERIC controller
            function c = shapeController(state, preTime, baseLevel, startTime, endTime, shapeData_someColumns, controllerIndex)
                % controllerIndex is to have multiple shapes simultaneously
                t = state.time - preTime * 1e-3;
                activeNow = (t > startTime & t < endTime);
                if any(activeNow)
                    actives = find(activeNow);
                    c = shapeData_someColumns(actives(controllerIndex),:);
                else
                    c = baseLevel;
                end
            end
            
            col_startTime = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'startTime')));
            col_endTime = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'endTime')));
%             TODO: change epoch property shapeData to shapeDataMatrix in
%             analysis
            
            % intensity
            col_intensity = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'intensity')));
            controllerIntensity = PropertyController(circ, 'color', @(s)shapeController(s, obj.preTime, obj.meanLevel, ...
                                                    obj.shapeDataMatrix(:,col_startTime), ...
                                                    obj.shapeDataMatrix(:,col_endTime), ...
                                                    obj.shapeDataMatrix(:,col_intensity), 1));
            presentation.addController(controllerIntensity);
            
            % diameter X
            col_diameter = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'diameter')));
            controllerDiameterX = PropertyController(circ, 'radiusX', @(s)shapeController(s, obj.preTime, 100, ...
                                                    obj.shapeDataMatrix(:,col_startTime), ...
                                                    obj.shapeDataMatrix(:,col_endTime), ...
                                                    obj.shapeDataMatrix(:,col_diameter) / 2, 1));
            presentation.addController(controllerDiameterX);
            
            % diameter Y
            controllerDiameterY = PropertyController(circ, 'radiusY', @(s)shapeController(s, obj.preTime, 100, ...
                                                    obj.shapeDataMatrix(:,col_startTime), ...
                                                    obj.shapeDataMatrix(:,col_endTime), ...
                                                    obj.shapeDataMatrix(:,col_diameter) / 2, 1));
            presentation.addController(controllerDiameterY);
            
            % position
            mpp = obj.rigConfig.micronsPerPixel;
            poscols = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'X'))) | ...
                      not(cellfun('isempty', strfind(obj.shapeDataColumns, 'Y')));
            positions = obj.shapeDataMatrix(:,poscols);
            positions_transformed = [positions(:,1)./mpp + obj.windowSize(1)/2, positions(:,2)./mpp + obj.windowSize(2)/2];
            controllerPosition = PropertyController(circ, 'position', @(s)shapeController(s, obj.preTime, [0, 0], ...
                                                    obj.shapeDataMatrix(:,col_startTime), ...
                                                    obj.shapeDataMatrix(:,col_endTime), ...
                                                    positions_transformed, 1));
            presentation.addController(controllerPosition);
            
            preparePresentation@StageProtocol(obj, presentation);
        end
        
        
        function stimTime = get.stimTime(obj)
            % add a bit to the end to make sure we get all the spots
          
            if obj.temporalAlignment > 0 & isempty(obj.epochNum)
                stimTime = round(1000 * (obj.temporalAlignment * 2.0 + 1.0));
            elseif obj.temporalAlignment > 0 & obj.epochNum <= 1
                stimTime = round(1000 * (obj.temporalAlignment * 2.0 + 1.0));
            else
                stimTime = round(1000 * (obj.spotTotalTime * obj.numSpots * obj.numValues * obj.numValueRepeats + 1.0));
            end
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