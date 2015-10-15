classdef StageProtocol < PulsedProtocol
    
    properties
        color
        patternsPerFrame = 1
        bitDepth
        blueLED = 5
        greenLED = 5
        NDF = 4
        ampHoldSignal = 0
        amp2HoldSignal = 0
        meanLevel = 0
    end
        
    properties (Dependent, SetAccess = private)
        amp2
    end
    
    properties (Hidden)
        stage
        windowSize
        frameTrackerPosition 
        lastPresentation = []
        filterWheel
    end
    
    properties (Dependent)
        RstarMean
        patternRate
    end
        
    methods
        
        function [tf , msg] = isCompatibleWithRigConfig(obj, rigConfig)
            [tf, msg] = isCompatibleWithRigConfig@PulsedProtocol(obj, rigConfig);
            
            if tf && exist('StageClient', 'class') ~= 8
                tf = false;
                msg = 'This protocol requires Stage.';
            end
        end
        
        
        function obj = init(obj, rigConfig)
            global DEMO_MODE;
            init@PulsedProtocol(obj, rigConfig);
            
            obj.frameTrackerPosition = rigConfig.frameTrackerPosition;
            
            if exist('LcrStageClient', 'class') == 8
                obj.stage = LcrStageClient();
            end
            
            if ~DEMO_MODE
                obj.filterWheel = serial(rigConfig.filterWheelComPort, 'BaudRate', 115200,'DataBits',8,'StopBits',1,'Terminator','CR');
            end
        end
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@PulsedProtocol(obj, parameterName);
                   
            switch parameterName
                case 'meanLevel'
                    p.units = 'rel';
                case 'intensity'
                    p.units = 'rel';
                case 'color'
                    p.defaultValue = {'blue','green','cyan','none'};
                case 'bitDepth'
                    p.defaultValue = num2cell(8:-1:1);
                case {'frameRate', 'patternRate'}
                    p.units = 'Hz';
                case 'RstarMean'
                    p.units = 'R*/rod/s';
            end
            
            
        end
        
        function prepareRun(obj)
            global DEMO_MODE;
            prepareRun@PulsedProtocol(obj);
            
            if ~DEMO_MODE
                %setFilterWheel
                obj.setFilterWheel(obj.NDF);
            end
            
            %always start with new presentation
            obj.lastPresentation = [];
            try
                obj.stage.connect('localhost');
            catch e
                waitfor(errordlg('Unable to connect to Stage server.'));
                rethrow(e);
            end
            
            obj.windowSize = obj.stage.getCanvasSize();
            
            % Open a custom figure to display the duration of each frame presented.
            obj.openFigure('Custom', 'Name', 'Frame Durations', ...
                'UpdateCallback', @updateFrameDurations, ...
                'xlabel', 'Frame number', 'ylabel', 'Interval (s)');
            
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures for single trial responses of both amps
                obj.openFigure('Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                if ~isempty(obj.amp2)
                    obj.openFigure('Response', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                end
            end
            
        end
        
        
        function updateFrameDurations(obj, epoch, axesHandle) %#ok<INUSL>
            info = obj.stage.getPlayInfo;
            if isa(info, 'MException')
                obj.stop();
                waitfor(errordlg(['Stage encountered an error during the presentation.' char(10) char(10) getReport(info, 'extended', 'hyperlinks', 'off')]));
                return;
            end
            
            persistent flipDurationsLine;
            
            if obj.numEpochsCompleted == 1
                flipDurationsLine = line(1:numel(info.flipDurations), info.flipDurations, 'Parent', axesHandle, 'color', 'k');
                %xlabel(axesHandle, 'frame');
                %ylabel(axesHandle, 'sec');
            else
                set(flipDurationsLine, 'Xdata', 1:numel(info.flipDurations), 'Ydata', info.flipDurations);
                %disp(length(info.flipDurations));
            end
        end
        
        
        function preloadQueue(obj) %#ok<MANU>
            % Do nothing to suppress preloading.
        end
        
        
         function prepareEpoch(obj, epoch)
            global DEMO_MODE;
            
            prepareEpoch@PulsedProtocol(obj, epoch);
            
            % Enable wait for trigger so the epoch and presentation may be syncronized.
            if DEMO_MODE
                epoch.waitForTrigger = false;
            else
                epoch.waitForTrigger = true;
            end
        end
        
        
        function setBackground(obj,presentation)
            % Create a background stimulus (canvas.setClearColor should not be used in pattern mode).
            background = Rectangle();
            background.size = [obj.windowSize(1), obj.windowSize(2)];
            background.position = [obj.windowSize(1), obj.windowSize(2)] / 2;
            background.color = obj.meanLevel;
            presentation.addStimulus(background);
        end
        
        function preparePresentation(obj, presentation) %#ok<INUSD>
            %set LightCrafter status
            obj.stage.setLcrPatternAttributes(obj.bitDepth, obj.color, obj.patternsPerFrame);
            obj.stage.setLcrLedCurrents(0, obj.greenLED, obj.blueLED);
            
            % Override this method to add stimuli and controllers to the visual presentation.
            frameTracker = FrameTracker();
            frameTracker.position = obj.frameTrackerPosition; %gets this from RigConfig
            controller = PropertyController(frameTracker, 'color', @(s)s.time<obj.preTime*1E-3); %temp hack, frametracker only for preTime
            presentation.addController(controller);
            presentation.addStimulus(frameTracker);
        end
        
        function queueEpoch(obj, epoch)
            queueEpoch@PulsedProtocol(obj, epoch);
            
            % Create the Stage presentation.
            duration = (obj.preTime + obj.stimTime + obj.tailTime) * 1e-3;
            presentation = Presentation(duration);
            obj.preparePresentation(presentation);

            if obj.isSamePresentation(presentation, obj.lastPresentation)
                %disp('found repeat presentation')
                obj.stage.replay();
            else
                %disp('found different presentation')
                if obj.patternRate > 60 %HACK: computer can't render on the fly for > 60Hz
                    obj.stage.play(presentation, 1);
                else
                    obj.stage.play(presentation, 0);
                end
            end
            obj.lastPresentation = presentation;
        end
        
        
        function waitToContinueQueuing(obj)
            waitToContinueQueuing@PulsedProtocol(obj);
            
            % Wait until the previous epoch and interval are complete.
            while (obj.numEpochsQueued > obj.numEpochsCompleted || obj.numIntervalsQueued > obj.numIntervalsCompleted) && strcmp(obj.state, 'running')
                pause(0.01);
            end
        end
        
        
        function completeRun(obj)
            completeRun@PulsedProtocol(obj);
            obj.stage.disconnect();
            %save data
            for i=1:length(obj.figureHandlers)
                if ismethod(obj.figureHandlers{i}, 'saveFigureData')
                    disp('found FigureHandler to save')                    
                    if ~isempty(obj.persistor) %epochs being saved?
                        cellID = obj.symphonyUI.epochGroup.userProperties.cellID;
                        rigName = obj.symphonyUI.epochGroup.userProperties.rigName;
                        year = obj.symphonyUI.epochGroup.startTime.Date.Year;
                        month = obj.symphonyUI.epochGroup.startTime.Date.Month;
                        day = obj.symphonyUI.epochGroup.startTime.Date.Day;
                        %hour = obj.symphonyUI.epochGroup.startTime.Hour;
                        %minute = obj.symphonyUI.epochGroup.startTime.Minute;
                        outpath = obj.symphonyUI.epochGroup.outputPath;
                        curTimeStr = num2str(rem(now,1), 5);
                        fname = fullfile(outpath, [obj.displayName '_' obj.figureHandlers{i}.figureType '_' num2str(year) '_' num2str(month) '_' num2str(day) '-cell' cellID rigName '-' curTimeStr]); 
                        obj.figureHandlers{i}.saveFigureData(fname);
                    end
                end
            end
            
        end
        
        function sobj = saveobj(obj)
            % The entire protocol is serialized and sent to the remote Stage server. Some properties may be set to empty
            % to reduce the size of the serialized protocol.
            sobj = copy(obj);
            sobj.stage = [];
            sobj.symphonyUI = [];
            sobj.rigConfig = [];
            sobj.persistor = [];
            sobj.lastPresentation = [];
        end
        
        function setFilterWheel(obj, value)
            filterIndex = find(obj.rigConfig.filterWheelNDFs == value);
            if length(filterIndex) ~= 1 %#ok<ISMT>
                disp(['Error: filter value ' num2str(value) ' not found']);
                return;
            end
            %move wheel
            fopen(obj.filterWheel);
            fprintf(obj.filterWheel,'pos?\n');
            curPosition = fscanf(obj.filterWheel);
            if filterIndex==curPosition
                %do nothing, already in correct position
            else
                fprintf(obj.filterWheel,['pos=' num2str(filterIndex) '\n']);
                pause(4);
            end
            fclose(obj.filterWheel);            
        end
        
        function amp2 = get.amp2(obj)
            amp2 = obj.get_amp2();
        end
        
        function RstarMean = get.RstarMean(obj)
            global DEMO_MODE;
            if isempty(obj.color) || DEMO_MODE || isempty(obj.NDF)
                RstarMean = [];
            else
                filterIndex = find(obj.rigConfig.filterWheelNDFs == obj.NDF);
                if isempty(filterIndex)
                    disp('Error: bad NDF value');
                    RstarMean = [];
                else
                    NDF_attenuation = obj.rigConfig.NDFattenuation(filterIndex);
                    [R,M,S] = photoIsom2(obj.blueLED, obj.greenLED, obj.color, obj.rigConfig.fitBlue, obj.rigConfig.fitGreen);
                    RstarMean = R * obj.meanLevel * NDF_attenuation;
                end
            end
        end
        
        function patternRate = get.patternRate(obj)
            %HACK: hard-coded 60 Hz
            patternRate = 60*obj.patternsPerFrame;
        end
        
    end
    
    methods(Static)
        function samePres = isSamePresentation(pres1, pres2)
            %disp('checking presentation equality')
            samePres = 0;            
            if isempty(pres1) || isempty(pres2)
                return;
            end
            %keyboard;
            controllers_p1 = pres1.controllers;
            controllers_p2 = pres2.controllers;
            
            p1.duration = pres1.duration;
            p1.stimuli = pres1.stimuli;
            p2.duration = pres2.duration;
            p2.stimuli = pres2.stimuli;
            
            %disp('checking stimuli')
            if ~isequal(p1, p2)
                return
            end
            L = length(controllers_p1);
            if L ~= length(controllers_p2), return; end
            %temp - not checking controllers! They are empty!
            %disp('checking controllers')
%             for i=1:L
%                 cont1 = controllers_p1{i};
%                 cont2 = controllers_p2{i};                
%                 if ~isequal(cont1{1},cont2{1}), return; end
%                 if ~isequal(cont1{2},cont2{2}), return; end
%                 if ~isequal(func2str(cont1{3}),func2str(cont2{3})), return; end
%             end
            samePres = 1;
        end
    end
    
end