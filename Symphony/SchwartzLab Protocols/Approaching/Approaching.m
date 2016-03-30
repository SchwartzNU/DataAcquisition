classdef Approaching < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.Approaching'
        version = 1
        displayName = 'Approaching'
    end
    
    properties
        amp
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        tailTime = 1000 %will be rounded to account for frame rate
        %stimTime = 2000; % = static+changing
        staticTimePre = 1000;
        dynamicTime = 1000;
        staticTimePost = 1000;
        
        %speedApproach = 1; %units??
        initSizeX = 200; initSizeY = 200; %microns
        finalScaleFactor = 2;
        speedLateral = 500; %microns/s
        directionLateral = 0; %deg.
        imageFileName = '....';
        numSquares = 10;
        intensity = 0.5;
        %randSeed = 1;
        randPermut = false;
        receding = false;
        instantaneous = false;
        centerChecker = 'dark';
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Hidden)
        randSeed;
        interleave
        curEpStim
        trueNumSquares
        trueDynamicTime
        trueStimTime
        trueRescalingRate
    end
    
    properties (Dependent)
        squareSizeX;
        rescalingRate;
        stimTime;
    end
    
    
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case 'dynamicTime'
                    p.units = 'ms';
                    p.displayTab = 'mostUsed';
                case {'initSizeX','initSizeY'}
                    p.units = 'um';
                    %p.displayTab = 'mostUsed';
                case 'squareSizeX'
                    p.units = 'um';
                    p.displayTab = 'mostUsed';
                case {'finalScaleFactor','numSquares','randPermut','receding','instantaneous'}
                    p.displayTab = 'mostUsed';
                case {'speedLateral'}
                    p.units = 'um/s';
                    p.displayTab = 'mostUsed';
                case {'intensity', 'meanLevel'}
                    p.displayTab = 'mostUsed';
                    p.units = 'rel';
                case {'rescalingRate'}
                    p.displayTab = 'mostUsed';
                    p.units = '1/s';
                case 'centerChecker'
                    p.defaultValue = {'dark','bright','split','random'};
                    p.displayTab = 'mostUsed';
            end
        end
        
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            % Randomize
            scurr = rng('shuffle');
            obj.randSeed = scurr.Seed;
            
            %             % Random interleaving of epochs
            %             interleaveIndex = randsample(obj.numberOfAverages, floor(obj.numberOfAverages/2));
            %             localInterleave = zeros(obj.numberOfAverages, 1);
            %             localInterleave(interleaveIndex) = 1;
            %             obj.interleave = localInterleave;
            %             disp(localInterleave)
            
            % Random interleaving of epochs
            stimIsChecked = [obj.randPermut; obj.receding; obj.instantaneous];
            numInterleavedStimuli = double(1 + obj.randPermut + obj.receding + obj.instantaneous); %1 is default - approaching.
            numSingleStimEpochs = floor(double(obj.numberOfAverages)/numInterleavedStimuli);
            localInterleave = zeros(obj.numberOfAverages, 1);
            for I = 1:length(stimIsChecked)
                if stimIsChecked(I)
                    localInterleave(1+numSingleStimEpochs*(I-1):numSingleStimEpochs*I) = I;
                    %0  -approaching
                    %1  -shuffled
                    %2  -receding
                    %3  -instantaneous
                end;
            end;
            obj.interleave = localInterleave(randperm(obj.numberOfAverages));
            disp(obj.interleave)
            disp(stimIsChecked)
            
            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', 'curEpStim', ...
                        'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
%                     obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curEpStim', ...
%                         'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
%                         'Mode', 'Cell attached', ...
%                         'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', 'curEpStim', ...
                            'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
                            'LineColor', 'r');
%                         obj.openFigure('1D Response', obj.amp, 'EpochParam', 'curEpStim', ...
%                             'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
%                             'Mode', 'Cell attached', ...
%                             'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold, ...
%                             'LineColor', 'r');
                    end
                end
            end
            
            
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            % Randomize angles if this the first epoch
            %             if obj.numEpochsQueued == 0
            %                 scurr = rng('shuffle');
            %                 obj.randSeed = scurr.Seed;
            %             end
            %             epoch.addParameter('randSeed', obj.randSeed);
            
            obj.curEpStim = obj.interleave(obj.numEpochsQueued+1);
            epoch.addParameter('curEpStim', obj.curEpStim);
            
            %%%% Zero true dynamic time if 'instantaneous' is checked
            if ~(obj.curEpStim == 3)
                obj.trueDynamicTime = obj.dynamicTime;
                obj.trueStimTime = obj.stimTime;
                obj.trueRescalingRate = obj.rescalingRate;
            else
                obj.trueDynamicTime = 0;
                obj.trueStimTime = obj.stimTime-obj.dynamicTime;
                obj.trueRescalingRate = inf;
            end;
            %%%% 
            %set true num. squares for dark/split/bright center
            tNumSquares = obj.numSquares;
            splitAndOdd =  strcmp(obj.centerChecker,'split') && mod( tNumSquares, 2) == 1;
            nonSplitAndEven = (strcmp(obj.centerChecker,'bright') || strcmp(obj.centerChecker,'dark')) && mod( tNumSquares, 2) == 0;
            if splitAndOdd || nonSplitAndEven
                tNumSquares = tNumSquares+1;
            end;
            obj.trueNumSquares = tNumSquares;
            % % %
            epoch.addParameter('randSeed', obj.randSeed);
            epoch.addParameter('interleave', obj.interleave);
            epoch.addParameter('trueNumSquares', obj.trueNumSquares);
            epoch.addParameter('trueDynamicTime', obj.trueDynamicTime);
            epoch.addParameter('trueRescalingRate', obj.trueRescalingRate);
            epoch.addParameter('trueStimTime', obj.trueStimTime);
        end
        
        function preparePresentation(obj, presentation)
            %%% constants: initial conditions for controllers
            pixInitSize = [obj.initSizeX, obj.initSizeY]./obj.rigConfig.micronsPerPixel;
            initPosition = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            pixSpeedLat = obj.speedLateral./obj.rigConfig.micronsPerPixel;
            %%%
            
            
            %set bg
            obj.setBackground(presentation);
            
            %%%% Make a checkerboard stimulus object %%%%
            % Create an initial checkerboard image matrix.
            %RANDOM CHECKERBOARD
            %             rng(obj.randSeed);
            %             checkerboardMatrix = uint8(randi([0,1],(obj.numSquares)) * 255);
            %             %was rand(10).*255
            
            if ~strcmp(obj.centerChecker,'random')
                %REGULAR CHECKERBOARD                
                

                
                %modifiedNumSquares = obj.numSquares;
                tNumSquares = obj.trueNumSquares;
                if mod(tNumSquares, 2) == 0
                    cb = mod(1:(tNumSquares+1)^2,2);
                    cb = reshape(cb, [(tNumSquares+1),(tNumSquares+1)]);
                    cb = cb(1:end-1,1:end-1);
                else
                    cb = mod(1:tNumSquares^2,2);
                    cb = reshape(cb, [tNumSquares,tNumSquares]);
                end;
                if strcmp(obj.centerChecker,'dark')
                    cb = 1-cb;
                end;
                
            else
               %RANDOM CHECKERBOARD
               cb = randi([0,1],(obj.numSquares));
            end;
            
            checkerboardMatrix = uint8(cb.*255);
%             disp(checkerboardMatrix);
            % % %
            
            
            
            % Create the checkerboard stimulus.
            checkerboard = Image(checkerboardMatrix);
            checkerboard.position = initPosition;
            %             % Create an aperture (masked rectangle) stimulus to sit on top of the image stimulus.
            %             aperture = Rectangle();
            %             aperture.color = 0;
            %             aperture.size = [500, 500];
            %             mask = Mask.createCircularAperture(0.4);
            %             aperture.setMask(mask);
            %             %%%
            
            unitStep = [cosd(obj.directionLateral), sind(obj.directionLateral)];
            
            %%%% Set the minifying and magnifying functions to form discrete stixels.
            checkerboard.setMinFunction(GL.NEAREST);
            checkerboard.setMagFunction(GL.NEAREST);
            %%%%
            
            %%% function to modify simulus property %%%
            function sz = modifyScaleFactor(state, pixInitSize, obj)
                
                %                 function scFac = scFactor(dynamicTime,finalFactor)
                %                     %linear spacing
                %                     scFac = (1+dynamicTime*(finalFactor-1));
                %                 end
                
                function scFac = scFactor(t_dynamic,finalFactor,maxDynamicTime,curEpStim,patternRate)
                    %log spacing; random permutation option
                    alpha = log(finalFactor)/maxDynamicTime;
                    
                    %Add shuffled and receding versions of stimulus
                    nFrames = round(maxDynamicTime*patternRate);
                    dynTimeAxis = (1:nFrames)/patternRate;
                    if curEpStim == 1
                        dynTimeAxisPerm = randperm(nFrames)./patternRate;
                        shuffledTime = dynTimeAxisPerm(round(dynTimeAxis*10^5) == round(t_dynamic*10^5));
                        t_dynamic = shuffledTime;
                    elseif curEpStim == 2
                        dynTimeAxisPerm = (nFrames:-1:1)./patternRate;
                        reveresedTime = dynTimeAxisPerm(round(dynTimeAxis*10^5) == round(t_dynamic*10^5));
                        t_dynamic = reveresedTime;
                    end;
                    % %
                    
                    scFac = exp(alpha*t_dynamic);
                end
                
                
                if state.time<=(obj.preTime+obj.staticTimePre)/1E3
                    if obj.curEpStim~=2
                        sz = pixInitSize;
                    else
                        sz = pixInitSize * obj.finalScaleFactor;
                    end;
                elseif  state.time<=(obj.preTime+obj.staticTimePre+obj.trueDynamicTime)/1E3 %stimulus varying with time
                    t_dynamic = (state.time-(obj.preTime+obj.staticTimePre)/1E3);
                    sz = pixInitSize * scFactor(t_dynamic,obj.finalScaleFactor,obj.trueDynamicTime/1E3,obj.curEpStim, obj.patternRate);
                else
                    if obj.curEpStim~=2
                        sz = pixInitSize * obj.finalScaleFactor;
                    else
                        sz = pixInitSize;
                    end;
                end;

            end
            
            % % % Make a property controller to propagate property of checkerboard % % %
            %checkerboardImageController = PropertyController(checkerboard, 'imageMatrix', @(s)uint8(rand(10, 10) * 255));
            scaleFactorController = PropertyController(checkerboard, 'size', @(s)modifyScaleFactor(s, pixInitSize, obj));
            
            function pos = changePosition(state, obj, initPosition, unitStep, pixSpeedLat)
                if state.time<=obj.preTime/1E3
                    pos = [NaN,NaN];
                elseif state.time<=(obj.preTime+obj.staticTimePre)/1E3
                    pos = initPosition;
                elseif state.time<=(obj.preTime+obj.staticTimePre+obj.trueDynamicTime)/1E3
                    pos = initPosition+(state.time-(obj.preTime+obj.staticTimePre)/1E3)*pixSpeedLat.*unitStep;
                elseif state.time<=(obj.preTime+obj.stimTime)/1E3
                    pos = initPosition+(obj.trueDynamicTime/1E3)*pixSpeedLat.*unitStep;
                else
                    pos = [NaN,NaN];
                end;
                
            end
            
            positionController = PropertyController(checkerboard, 'position', @(s)changePosition(s, obj, initPosition, unitStep, pixSpeedLat));
            
            % % % Add checkerboard stimulus and controller to presentation % % %
            presentation.addStimulus(checkerboard);
            
            %presentation.addController(checkerboardImageController);
            presentation.addController(scaleFactorController);
            presentation.addController(positionController);
            %             presentation.addStimulus(aperture);
            
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
            stimTime = obj.staticTimePre+obj.dynamicTime+obj.staticTimePost;
            %NOTE: this stimTime is WRONG for 'instantaneous' epochs
            %(because trueDynamicTime == 0)
        end
        
        function squareSizeX = get.squareSizeX(obj)
            squareSizeX = obj.initSizeX./obj.numSquares;
        end
        
        function rescalingRate = get.rescalingRate(obj)
            %rescalingRate = obj.finalScaleFactor/(obj.stimTime./1E3); %linear in time
            
            %exp in time
            rescalingRate = log(obj.finalScaleFactor)/(obj.dynamicTime./1E3);
        end
    end
    
end