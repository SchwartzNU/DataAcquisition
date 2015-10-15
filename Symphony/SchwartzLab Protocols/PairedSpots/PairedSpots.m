classdef PairedSpots < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.PairedSpots'
        version = 1
        displayName = 'Paired Spots'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        intensity = 0.1;
        
        spotSize = 100 %um
        Nspots = 4
        spotSeparation = 100 %um
        angle
    end
    
    properties
        numberOfAverages = uint16(10)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Dependent)
        Nconditions 
    end
    
    properties (Hidden)
        spot1ID
        spot2ID
        spot1_X
        spot1_Y
        spot2_X
        spot2_Y
        isPair
        spotLocations
        pairChoiceVector 
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case {'spotSize', 'spotSeparation'};                    
                    p.units = 'um';   
                    p.displayTab = 'mostUsed';
                case {'intensity', 'meanLevel'}
                    p.units = 'rel';
                    p.displayTab = 'mostUsed';
                case 'angle'
                    p.defaultValue = {0, 45, 90, 135};                    
                    p.displayTab = 'mostUsed';
                case {'Nspots', 'Nconditions'}
                    p.displayTab = 'mostUsed';
            end
        end
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set spot location vectors
            obj.pairChoiceVector = nchoosek(1:obj.Nspots,2);
            
            switch obj.angle
                case 0
                   pixelStep = round(obj.spotSeparation / obj.rigConfig.micronsPerPixel);            
                   firstPos = round(obj.windowSize(1)/2) - floor(obj.Nspots/2) * pixelStep;
                   xvals = firstPos:pixelStep:firstPos+(obj.Nspots-1)*pixelStep;
                   yvals = ones(1,obj.Nspots).*obj.windowSize(2)/2;
                case 45
                   pixelStep = round((obj.spotSeparation / obj.rigConfig.micronsPerPixel) / sqrt(2));             
                   firstPos_X = round(obj.windowSize(1)/2) - floor(obj.Nspots/2) * pixelStep;
                   xvals = firstPos_X:pixelStep:firstPos_X+(obj.Nspots-1)*pixelStep;
                   firstPos_Y = round(obj.windowSize(2)/2) - floor(obj.Nspots/2) * pixelStep;
                   yvals = firstPos_Y:pixelStep:firstPos_Y+(obj.Nspots-1)*pixelStep;
                case 90
                   pixelStep = round(obj.spotSeparation / obj.rigConfig.micronsPerPixel);            
                   firstPos = round(obj.windowSize(2)/2) - floor(obj.Nspots/2) * pixelStep;
                   yvals = firstPos:pixelStep:firstPos+(obj.Nspots-1)*pixelStep;
                   xvals = ones(1,obj.Nspots).*obj.windowSize(1)/2;
                case 135
                   pixelStep = round((obj.spotSeparation / obj.rigConfig.micronsPerPixel) / sqrt(2));
                   firstPos_X = round(obj.windowSize(1)/2) - floor(obj.Nspots/2) * pixelStep;
                   xvals = firstPos_X:pixelStep:firstPos_X+(obj.Nspots-1)*pixelStep;
                   firstPos_Y = round(obj.windowSize(2)/2) - floor(obj.Nspots/2) * pixelStep;
                   yvals = firstPos_Y+(obj.Nspots-1)*pixelStep:-pixelStep:firstPos_Y;
            end
            obj.spotLocations = [xvals' yvals'];
            obj.spotLocations

            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Paired Spots', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Paired Spots', obj.amp2,'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                    end
                end
            end
        end
        
         function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            % compute current positions and add parameters for them
            conditionInd = mod(obj.numEpochsQueued, obj.Nconditions) + 1;
            if conditionInd <= obj.Nspots %single spot condition
                obj.isPair = false;
                %get current position
                obj.spot1ID = conditionInd;
                obj.spot1_X = obj.spotLocations(obj.spot1ID,1);
                obj.spot1_Y = obj.spotLocations(obj.spot1ID,2);
                epoch.addParameter('spot1_X', obj.spot1_X);
                epoch.addParameter('spot1_Y', obj.spot1_Y);
                epoch.addParameter('spot1ID', obj.spot1ID);
            else
                obj.isPair = true;
                %get current position for both spots
                pairInd = conditionInd - obj.Nspots;
                epoch.addParameter('pairID', pairInd)
                obj.spot1ID = obj.pairChoiceVector(pairInd,1);
                obj.spot2ID = obj.pairChoiceVector(pairInd,2);
                obj.spot1_X = obj.spotLocations(obj.spot1ID,1);
                obj.spot1_Y = obj.spotLocations(obj.spot1ID,2);
                epoch.addParameter('spot1_X', obj.spot1_X);
                epoch.addParameter('spot1_Y', obj.spot1_Y);
                epoch.addParameter('spot1ID', obj.spot1ID);
                epoch.addParameter('spot2ID', obj.spot2ID);
                obj.spot2_X = obj.spotLocations(obj.spot2ID,1);
                obj.spot2_Y = obj.spotLocations(obj.spot2ID,2);
                epoch.addParameter('spot2_X', obj.spot2_X);
                epoch.addParameter('spot2_Y', obj.spot2_Y);
                distance = round(obj.rigConfig.micronsPerPixel*sqrt((obj.spot1_X - obj.spot2_X)^2 + (obj.spot1_Y - obj.spot2_Y)^2)); %um
                epoch.addParameter('pairDistance',distance);
            end
            
            epoch.addParameter('Npairs', size(obj.pairChoiceVector,1));
            epoch.addParameter('isPair', obj.isPair);
        end
        
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            spot1 = Ellipse();
            spot1.radiusX = round(obj.spotSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
            spot1.radiusY = spot1.radiusX;
            spot1.position = [obj.spot1_X, obj.spot1_Y];
            presentation.addStimulus(spot1);
            
            if obj.isPair
                spot2 = Ellipse();
                spot2.radiusX = round(obj.spotSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
                spot2.radiusY = spot2.radiusX;
                spot2.position = [obj.spot2_X, obj.spot2_Y];
                presentation.addStimulus(spot2);
                
                controller = PropertyController(spot2, 'color', @(s)onDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
                presentation.addController(controller);
            end
            
            function c = onDuringStim(state, preTime, stimTime, intensity, meanLevel)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    c = intensity;
                else
                    c = meanLevel;
                end
            end
            
            controller = PropertyController(spot1, 'color', @(s)onDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
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
  
        function Nconditions = get.Nconditions(obj)
            Nconditions = obj.Nspots + nchoosek(obj.Nspots,2);            
        end
        
        
    end
    
end