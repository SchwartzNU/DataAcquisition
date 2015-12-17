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
        
        runTimeSeconds = 60;
        
        ISOResponse = false;
                                     
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
        shapeResponseFigure
%         positions
        shapeDataMatrix
        shapeDataColumns
        sessionId
        epochNum
        autoContinueRun = 1;
        autoStimTime = 1000;
        startTime = 0;
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
            obj.startTime = clock;
            obj.autoContinueRun = 1;
            
            obj.shapeResponseFigure = obj.openFigure('Shape Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd,...
                'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, 'shapePlotMode','spatial');
            
%             obj.openFigure('PSTH', obj.amp, ...
%                 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
%                 'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
            
            prepareRun@StageProtocol(obj);

        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            obj.epochNum = obj.epochNum + 1;
            
            prepareEpoch@StageProtocol(obj, epoch);
            
%             epoch.addParameter('positions', obj.positions(:));
            p = struct();
            p.spotDiameter = obj.spotDiameter; %um
            p.searchDiameter = obj.searchDiameter;
            p.numSpots = obj.numSpots;
            p.spotTotalTime = obj.spotTotalTime;
            p.spotOnTime = obj.spotOnTime;
            
            p.valueMin = obj.valueMin;
            p.valueMax = obj.valueMax;
            p.numValues = obj.numValues;
            p.numValueRepeats = obj.numValueRepeats;
            p.epochNum = obj.epochNum;
            
            timeElapsed = etime(clock, obj.startTime);
            p.timeRemainingSeconds = obj.runTimeSeconds - timeElapsed;
%             obj.runTimeSeconds;
            
            mode = 'autoReceptiveField';
            if obj.ISOResponse
                mode = 'isoResponse';
            end
            runConfig = generateShapeStimulus(mode, p, obj.shapeResponseFigure.analysisData);
            obj.shapeDataColumns = runConfig.shapeDataColumns;
            obj.shapeDataMatrix = runConfig.shapeDataMatrix;
            
%             disp('prep continue run:')
%             disp(runConfig.autoContinueRun)
            
            obj.autoStimTime = runConfig.stimTime;
            obj.autoContinueRun = runConfig.autoContinueRun;
            
            epoch.addParameter('sessionId',obj.sessionId);
            epoch.addParameter('presentationId',obj.epochNum);
            epoch.addParameter('epochMode',runConfig.epochMode);
            epoch.addParameter('shapeDataMatrix', runConfig.shapeDataMatrix(:));
            epoch.addParameter('shapeDataColumns', strjoin(runConfig.shapeDataColumns,',')); 
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
            
            circ = Ellipse();
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
          
            stimTime = obj.autoStimTime;
%             if obj.temporalAlignment > 0 & isempty(obj.epochNum)
%                 stimTime = round(1000 * (obj.temporalAlignment * 2.0 + 1.0));
%             elseif obj.temporalAlignment > 0 & obj.epochNum <= 1
%                 stimTime = round(1000 * (obj.temporalAlignment * 2.0 + 1.0));
%             else
%                 stimTime = round(1000 * (obj.spotTotalTime * obj.numSpots * obj.numValues * obj.numValueRepeats + 1.0));
%             end
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
            
%             disp(obj.autoContinueRun)
            
            % Keep queuing until the requested number of averages have been queued.
            if keepQueuing
                keepQueuing = obj.autoContinueRun;
            end
        end
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@StageProtocol(obj);
            
%             disp(obj.autoContinueRun)
            
            % Keep going until the requested number of averages have been completed.
            if keepGoing
                keepGoing = obj.autoContinueRun;
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