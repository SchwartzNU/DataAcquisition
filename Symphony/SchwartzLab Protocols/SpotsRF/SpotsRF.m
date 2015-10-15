classdef SpotsRF < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.SpotsRF'
        version = 1
        displayName = 'Spots RF'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        intensity = 0.1
        
        spotSize = 20 %um
        Nradii = 1
        minRadius = 50
        maxRadius = 800
        spotSeparationBy %microns or degrees of angle
        spotSeparation = 30 %degrees
    end
    
    properties
        numberOfAverages = uint16(10)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Dependent)
        Nspots 
    end
    
    properties (Hidden)
        curSpotX
        curSpotY
        curShiftX
        curShiftY
        radiusList
        randOrder
        spotLocationsX
        spotLocationsY
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case 'spotSeparationBy'
                     p.displayTab = 'mostUsed';
                     p.defaultValue = {'degrees', 'microns'};
                case {'spotSize', 'minRadius', 'maxRadius'}
                    p.units = 'um';
                    p.displayTab = 'mostUsed';
                case 'spotSeparation'
                    p.units = 'um or degrees';
                    p.displayTab = 'mostUsed';
                case {'intensity', 'meanLevel'}
                    p.units = 'rel';
                    p.displayTab = 'mostUsed';
                case {'Nspots', 'Nradii'}
                    p.displayTab = 'mostUsed';
            end
        end
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set spot location vectors
            if obj.Nradii == 1
                obj.radiusList = round(obj.minRadius / obj.rigConfig.micronsPerPixel);
            else
                obj.radiusList = round(linspace(obj.minRadius, obj.maxRadius, obj.Nradii) / obj.rigConfig.micronsPerPixel);
            end
            
            obj.spotLocationsX = [];
            obj.spotLocationsY = [];
            for i=1:length(obj.radiusList)
                if strcmp(obj.spotSeparationBy, 'degrees')
                    angleList = round(0:obj.spotSeparation:359);
                else
                    circumference = 2*obj.radiusList(i)*pi;
                    angleList = round(359*(0:obj.spotSeparation/obj.rigConfig.micronsPerPixel:circumference)./circumference);
                end
                
                L = length(angleList);
                tempX = zeros(1,L);
                tempY = zeros(1,L);
                for j=1:L
                    tempX(j) = obj.radiusList(i) * cos(angleList(j)*pi/180);
                    tempY(j) = obj.radiusList(i) * sin(angleList(j)*pi/180);
                end
                obj.spotLocationsX = [obj.spotLocationsX, tempX];
                obj.spotLocationsY = [obj.spotLocationsY, tempY];
            end            
            
            %obj.spotLocationsX'
            %obj.spotLocationsY'

            nCycles = ceil(double(obj.numberOfAverages) / obj.Nspots);
            obj.randOrder = zeros(1, obj.Nspots*nCycles);
            ind = 1;
            for i=1:nCycles
                obj.randOrder(ind:ind+obj.Nspots-1) = randperm(obj.Nspots);
                ind = ind + obj.Nspots;                
            end
            obj.randOrder = obj.randOrder(1:obj.numberOfAverages);
            
            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Spots RF', obj.amp, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                    obj.openFigure('Spots RF', obj.amp, ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                            'Mode', 'Whole cell');
                else %cell-attached
                    obj.openFigure('Spots RF', obj.amp, ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'Mode', 'Cell attached', ...
                            'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Spots RF', obj.amp2, ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'ResponseType', obj.responseType, 'LowPassFreq', obj.lowPassFreq, ...
                            'Mode', 'Whole cell'); %change title for amp 2
                    else
                        obj.openFigure('Spots RF', obj.amp2, ...
                            'StartTime', obj.stimStart + obj.startTimeOffset*1E-3/obj.sampleRate, 'EndTime', obj.stimEnd + obj.endTimeOffset*1E-3/obj.sampleRate, ...
                            'Mode', 'Cell attached', ...
                            'SpikeDetectorMode', obj.amp2SpikeDetection, 'SpikeThreshold', obj.amp2SpikeThreshold);
                    end
                end
            end
        end
        
         function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            % compute current positions and add parameters for them
            obj.curShiftX = obj.spotLocationsX(obj.randOrder(obj.numEpochsQueued+1));
            obj.curShiftY = obj.spotLocationsY(obj.randOrder(obj.numEpochsQueued+1));
            obj.curSpotX = obj.curShiftX + obj.windowSize(1)/2;
            obj.curSpotY = obj.curShiftY + obj.windowSize(2)/2;
            
            epoch.addParameter('curShiftX', round(obj.curShiftX * obj.rigConfig.micronsPerPixel)); % back to microns
            epoch.addParameter('curShiftY', round(obj.curShiftY * obj.rigConfig.micronsPerPixel)); % back to microns
            epoch.addParameter('curSpotX', obj.curSpotX);
            epoch.addParameter('curSpotY', obj.curSpotY);
        end
        
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            spot1 = Ellipse();
            spot1.radiusX = round(obj.spotSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
            spot1.radiusY = spot1.radiusX;
            spot1.position = [obj.curSpotX, obj.curSpotY];
            presentation.addStimulus(spot1);            
            
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
  
        function Nspots = get.Nspots(obj)
            if obj.Nradii == 1
                radList = obj.minRadius;
            else
                radList = linspace(obj.minRadius, obj.maxRadius, obj.Nradii);
            end
            
            Nspots = 0;
            for i=1:length(radList)
                if strcmp(obj.spotSeparationBy, 'degrees')
                   Nspots = Nspots + floor(360 / obj.spotSeparation);                   
                else
                   Nspots = Nspots + floor(2*radList(i)*pi / obj.spotSeparation);
                end
            end            
        end
        
        
    end
    
end