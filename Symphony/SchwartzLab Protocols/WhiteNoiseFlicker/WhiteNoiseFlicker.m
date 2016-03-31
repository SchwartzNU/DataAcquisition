classdef WhiteNoiseFlicker < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.WhiteNoiseFlicker'
        version = 1
        displayName = 'White Noise Flicker'
    end
    
    properties
        amp
        preTime = 1000 
        stimTime = 8000
        tailTime = 1000
        noiseSD = 0.2 %relative light intensity units
        framesPerStep = 1; %at 60Hz
        stimMode %rand, repeated, or alternating
                
        %stim size in microns, use rigConfig to set microns per pixel
        spotSize = 300;
    end
    
    properties
        numberOfAverages = uint16(5)
        interpulseInterval = 0                
    end
    
    properties (Hidden)
       curSeed = 1;
       waveVec
    end
    
    methods           
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'framesPerStep'
                    p.displayTab = 'mostUsed';
                case 'noiseSD'
                    p.units = 'rel';
                    p.displayTab = 'mostUsed';
                case 'spotSize'
                    p.displayTab = 'mostUsed';
                    p.units = 'um';   
                case 'filterFreq'
                    p.units = 'Hz';
                    p.displayTab = 'mostUsed';
                case 'stimMode'
                    p.defaultValue = {'alternating','random', 'repeated'};
                    p.displayTab = 'mostUsed';
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            % Set amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'mV');
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'pA');
            end
            
            % Open figures for single trial responses of both amps
            obj.openFigure('Response', obj.amp);
            if ~isempty(obj.amp2)
                 obj.openFigure('Response', obj.amp2, 'LineColor', 'r');
            end
            
            % Open figures showing the mean response of the amp.
            obj.openFigure('Mean Response', obj.amp, 'GroupByParams', 'seedIsRepeated');
            if ~isempty(obj.amp2)
                if strcmp(obj.amp2Mode, 'Whole cell') 
                    obj.openFigure('Mean Response', obj.amp2, 'LineColor', 'r', 'GroupByParams', 'seedIsRepeated'); 
                elseif strcmp(obj.amp2Mode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                end
            end
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            if strcmp(obj.stimMode, 'repeated')
                obj.curSeed = 1;
            elseif strcmp(obj.stimMode, 'random')
                obj.curSeed = randi(10000);
            else %alternating
                if mod(obj.numEpochsQueued, 2)
                    obj.curSeed = 1;
                else
                    rng('shuffle');
                    obj.curSeed = randi(10000);
                end
            end
                
            %add seed parameter
            epoch.addParameter('randSeed', obj.curSeed);
            if obj.curSeed == 1
                epoch.addParameter('seedIsRepeated', 1);
            else
                epoch.addParameter('seedIsRepeated', 0);
            end
             
            disp([num2str(obj.numEpochsQueued) ' epochs queued']);
            disp(['Curseed = ' num2str(obj.curSeed)]);
            
             %set rand seed
            rng(obj.curSeed);
            
            nFrames = ceil((obj.stimTime/1000) * (obj.patternRate / obj.framesPerStep));
            obj.waveVec = randn(1,nFrames);   
            obj.waveVec = obj.waveVec .* obj.noiseSD; %set SD
            obj.waveVec = obj.waveVec + obj.meanLevel; %add mean
            obj.waveVec(obj.waveVec>1) = 1; %clip out of bounds values
            obj.waveVec(obj.waveVec>obj.meanLevel*2) = obj.meanLevel*2; %clip out of bounds values
            obj.waveVec(obj.waveVec<0) = 0;
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            spot = Ellipse();
            spot.radiusX = round(obj.spotSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
            spot.radiusY = spot.radiusX;
            %spot.color = obj.intensity;
            spot.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            presentation.addStimulus(spot);
            
            preFrames = floor(obj.patternRate / (obj.preTime/1000));
            
            function c = noiseStim(state, preTime, stimTime, preFrames, waveVec, frameStep, meanLevel)                
%                 if state.frame==1
%                     waveVec(1:5)
%                 end
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    c = waveVec(ceil((state.frame - preFrames) / frameStep));
                else                    
                    c = meanLevel;
                end
            end
            
%             obj.waveVec(1:5)
            controller = PropertyController(spot, 'color', @(s)noiseStim(s, obj.preTime, obj.stimTime, ...
                preFrames, obj.waveVec, obj.framesPerStep, obj.meanLevel));
            presentation.addController(controller);
            
            preparePresentation@StageProtocol(obj, presentation);            
        end
        
        
        function queueEpoch(obj, epoch)            
            % Call the base method to queue the actual epoch.
            queueEpoch@StageProtocol(obj, epoch);
            
            % Queue an inter-pulse interval after queuing the epoch.
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
        
        
    end
    
end