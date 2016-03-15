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
        spotDiameter = 22; %um
        searchDiameter = 300; %um
        numSpots = 100;
        spotTotalTime = 0.3;
        spotOnTime = 0.1;
        exVoltage = -60; %mV
        inVoltage = 20; %mV
        
        runTimeSeconds = 60;
        
        alternateVoltage = false; % WC only
        interactiveMode = false;
        
        valueMin = 0.1;
        valueMax = 1.0;
        numValues = 1;
        numValueRepeats = 2;
    end
    
    properties
        %interpulse interval in s
        interpulseInterval = 0;
    end
    
    properties (Hidden)
        shapeResponseFigure
        shapeResponseFigureWC
        %         positions
        shapeDataMatrix
        shapeDataColumns
        sessionId
        epochNum
        autoContinueRun = 1;
        autoStimTime = 1000;
        startTime = 0;
        currentVoltageIndex
        runConfig
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

            obj.sessionId = str2double(regexprep(num2str(fix(clock),'%1d'),' +','')); % this is how you get a datetime string number in MATLAB
            obj.epochNum = 0;
            obj.startTime = clock;
            obj.autoContinueRun = 1;
            
            if strcmp(obj.ampMode, 'Cell attached')
                obj.alternateVoltage = false;
            end
            if obj.alternateVoltage
                obj.currentVoltageIndex = 1;
            end
            
            obj.shapeResponseFigure = obj.openFigure('Shape Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd,...
                'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, 'shapePlotMode','spatial');
            
            
            if strcmp(obj.ampMode, 'Whole cell')
                obj.shapeResponseFigureWC = obj.openFigure('Shape Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd,...
                    'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, 'shapePlotMode','wholeCell');
            end
            
            if obj.numValues > 1        
                obj.shapeResponseFigureSubunit = obj.openFigure('Shape Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd,...
                    'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, 'shapePlotMode','subunit');
            end            
            %             obj.openFigure('PSTH', obj.amp, ...
            %                 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
            %                 'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
            
            prepareRun@StageProtocol(obj);
            
        end
        
        function prepareEpoch(obj, epoch)
            obj.epochNum = obj.epochNum + 1;
            generateNewStimulus = true;
            
            % alternate ex/in for same spots and settings
            if obj.alternateVoltage
                if obj.currentVoltageIndex == 1
                    obj.ampHoldSignal = obj.exVoltage;
                else  % inhibitory epoch, following Ex to mirror it
                    obj.ampHoldSignal = obj.inVoltage;
                    generateNewStimulus = false;
                end
                fprintf('setting amp voltage: %d mV; waiting 3 sec for stability\n', obj.ampHoldSignal);
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'mV'); % actually set it
                pause(3)
            end
            
            if generateNewStimulus
                
                analysisData = obj.shapeResponseFigure.analysisData;
                
                while true % loop preference setup until we make the choices we like
                    p = struct();
                    p.generatePositions = true;
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
                    p.refineCenter = obj.refineCenter;

                    timeElapsed = etime(clock, obj.startTime);
                    p.timeRemainingSeconds = obj.runTimeSeconds - timeElapsed; %only update time remaining if new stim, so Inhibitory always runs
                    %             obj.runTimeSeconds;

                    mode = 'autoReceptiveField';
                    if obj.ISOResponse
                        mode = 'isoResponse';
                    end

                    % INTERACTIVE MODE
                    % TODO: convert to GUI
                    % overwrite above params with custom if interactive
                    if obj.interactiveMode
                        
                        % choose active point set
                        % TODO: analysisData.pointSets
                        
                        figure(40);
                        plotShapeData(analysisData, 'plotSpatial_mean')
%                         disp('chose center then any edge point');
%                         [x,y] = ginput(2);
                        
                        
                        % choose next measurement
                        disp('map, curves, adapt, align, refvar','quit');
                        imode = input('measurement? ','s');
                        
                        if strcmp(imode, 'curves') % response curves
                            mode = 'responseCurves';
                            p.numSpots = input('num positions? ');
                            p.generatePositions = false;
                            p.numValues = input('num values? ');
                            p.numValueRepeats = input('num value repeats? ');

                        elseif strcmp(imode, 'map')
                            mode = 'receptiveField';
                            p.generatePositions = input('generate new positions? ');
                            if p.generatePositions
                                % TODO: display graph of current largest pointset's RF for clicking center and edge
                                p.center = input('center? ');
                                p.searchDiameter = input('search diameter? ');
                                p.spotDiameter = input('spot diameter? ');
                            end

                        elseif strcmp(imode, 'align')
                            mode = 'temporalAlignment';

                        elseif strcmp(imode, 'adapt')
                            mode = 'adaptationRegion';
                            p.adaptationSpotPositions = input('adaptation spot position [x1, y1]? ');
                            p.adaptationSpotFrequency = input('flicker frequency? ');
                            p.adaptationSpotDiameter = input('adaptation spot diameter? ');
                            p.probeSpotDiameter = input('probe spot diameter? ');
                            p.probeSpotDuration = input('probe spot duration? (sec) ');

                        elseif strcmp(imode, 'refvar')
                            mode = 'refineVariance';
                            p.variancePercentile = input('percentile of highest variance to refine (0-100)? ');
                            p.numValueRepeats = input('num value repeats to add? ');
                        
                        elseif strcmp(imode, 'refedges')
                            mode = 'refineEdges';
                            p.slopePercentile = input('percentile of highest slope to refine (0-100)? ');
                        
                        elseif strcmp(imode, 'quit')
                            mode = 'null';
                        end
                        
                        
                        
                    end

                    runConfig = generateShapeStimulus(mode, p, analysisData); %#ok<*PROPLC,*PROP>
                    obj.runConfig = runConfig;
                    obj.shapeDataColumns = runConfig.shapeDataColumns;
                    obj.shapeDataMatrix = runConfig.shapeDataMatrix;
                    obj.autoStimTime = runConfig.stimTime;

                    disp('this will run for %d sec', round(runConfig.stimTime / 1000))
                    contin = input('go? ');
                    if contin
                        break;
                    end
                end
                
            end
            
            % always continue if we're alternating and this is an excitatory epoch
            if obj.alternateVoltage && obj.currentVoltageIndex == 1
                obj.autoContinueRun = true;
            else
                obj.autoContinueRun = obj.runConfig.autoContinueRun;
            end
                            
            % set next epoch voltage
            if obj.epochNum == 1
                obj.currentVoltageIndex = 1; % do excitatory next epoch
            else
                nextIndices = [2;1];
                obj.currentVoltageIndex = nextIndices(obj.currentVoltageIndex);
            end
            
            epoch.addParameter('sessionId',obj.sessionId);
            epoch.addParameter('presentationId',obj.epochNum);
            epoch.addParameter('epochMode',obj.runConfig.epochMode);
            epoch.addParameter('shapeDataMatrix', obj.runConfig.shapeDataMatrix(:));
            epoch.addParameter('shapeDataColumns', strjoin(obj.runConfig.shapeDataColumns,','));
            
            prepareEpoch@StageProtocol(obj, epoch);
        end
        
        function preparePresentation(obj, presentation)
            
            col_intensity = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'intensity')));
            col_diameter = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'diameter')));    
            col_startTime = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'startTime')));
            col_endTime = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'endTime')));
            col_flickerFrequency = not(cellfun('isempty', strfind(obj.shapeDataColumns, 'flickerFrequency')));
            
            %set bg
            obj.setBackground(presentation);
            
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
            
            % Custom controllers
            % flicker
            function c = shapeFlickerController(state, preTime, baseLevel, startTime, endTime, shapeData_someColumns, controllerIndex)
                % controllerIndex is to have multiple shapes simultaneously
                t = state.time - preTime * 1e-3;
                activeNow = (t > startTime & t < endTime);
                if any(activeNow)
                    actives = find(activeNow);
                    [intensity, freq] = shapeData_someColumns(actives(controllerIndex),:);
                    c = intensity * (cos(t * freq) > 0);
                else
                    c = baseLevel;
                end
            end
            
            

            %             TODO: change epoch property shapeData to shapeDataMatrix in
            %             analysis
            
            % setup stimulus objects
            numCircles = obj.runConfig.numShapes; % these are in order of shapes being detected in the active shape set from the start & end times
            circles = cell(numCircles, 1);
            for ci = 1:numCircles
                circ = Ellipse();
                circles{ci} = circ;
                presentation.addStimulus(circles{ci});

                % intensity
                controllerIntensity = PropertyController(circ, 'color', @(s)shapeController(s, obj.preTime, obj.meanLevel, ...
                    obj.shapeDataMatrix(:,col_startTime), ...
                    obj.shapeDataMatrix(:,col_endTime), ...
                    obj.shapeDataMatrix(:,col_intensity), ci));
                presentation.addController(controllerIntensity);

                % diameter X
                controllerDiameterX = PropertyController(circ, 'radiusX', @(s)shapeController(s, obj.preTime, 100, ...
                    obj.shapeDataMatrix(:,col_startTime), ...
                    obj.shapeDataMatrix(:,col_endTime), ...
                    obj.shapeDataMatrix(:,col_diameter) / 2, ci));
                presentation.addController(controllerDiameterX);

                % diameter Y
                controllerDiameterY = PropertyController(circ, 'radiusY', @(s)shapeController(s, obj.preTime, 100, ...
                    obj.shapeDataMatrix(:,col_startTime), ...
                    obj.shapeDataMatrix(:,col_endTime), ...
                    obj.shapeDataMatrix(:,col_diameter) / 2, ci));
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
                    positions_transformed, ci));
                presentation.addController(controllerPosition);

                % flicker
                controllerFlicker = PropertyController(circ, 'intensity', @(s)shapeFlickerController(s, obj.preTime, obj.meanLevel, ...
                    obj.shapeDataMatrix(:,col_startTime), ...
                    obj.shapeDataMatrix(:,col_endTime), ...
                    obj.shapeDataMatrix(:,[col_intensity,col_flickerFrequency]), ci));
                presentation.addController(controllerFlicker);
            
            end % circle loop
            
            preparePresentation@StageProtocol(obj, presentation);
        end
        
        
        function stimTime = get.stimTime(obj)
            stimTime = obj.autoStimTime;
        end
        
        function values = get.values(obj)
            values = linspace(obj.valueMin, obj.valueMax, obj.numValues);
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