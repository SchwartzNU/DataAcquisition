classdef ContrastResponse < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.ContrastResponse'
        version = 1
        displayName = 'Contrast Response'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        %mean (bg) and amplitude of pulse        
        contrastNSteps = 5
        maxContrast = 1;
        contrastDirection 
        
        spotSize = 300; %microns
        
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Dependent)
        minContrast 
    end
    
    properties (Hidden)
        contrastValues
        intensityValues
        contrast
        intensity
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case 'spotSize'
                    p.units = 'um';   
                case 'meanIntensity'
                    p.units = 'rel';
                case 'contrastDirection'
                    p.defaultValue = {'both', 'positive', 'negative'};
                case 'meanLevel'
                    p.defaultValue = 0.5;
            end
        end

        function prepareRun(obj)
            global DEMO_MODE;
            %force 8 bit
            obj.bitDepth = 8;
            
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set contrast and intensity values
            if strcmp(obj.contrastDirection, 'positive')
                ex = linspace(0,obj.maxContrast,obj.contrastNSteps+1);
                temp = obj.maxContrast * (10.^ex - 1) / (10^obj.maxContrast - 1);
                obj.contrastValues = temp(2:end);
            elseif strcmp(obj.contrastDirection, 'negative')
                ex = linspace(0,obj.maxContrast,obj.contrastNSteps+1);
                temp = obj.maxContrast * (10.^ex - 1) / (10^obj.maxContrast - 1);
                obj.contrastValues = -temp(2:end);
            else
                ex = linspace(0,obj.maxContrast,obj.contrastNSteps+1);
                temp = obj.maxContrast * (10.^ex - 1) / (10^obj.maxContrast - 1);
                obj.contrastValues = [-fliplr(temp(2:end)), temp(2:end)];
            end
            %obj.contrastValues            
            obj.intensityValues = obj.meanLevel + (obj.contrastValues.*obj.meanLevel);
            %obj.intensityValues
            
            if ~DEMO_MODE %don't open response figures in demo moe
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'contrast'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', {'contrast'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', {'contrast'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', {'contrast'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                    end
                end
            end
            
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            % compute current contrast index     
            if strcmp(obj.contrastDirection, 'both')
                contrastValInd = mod(obj.numEpochsQueued, obj.contrastNSteps*2) + 1;
            else
                contrastValInd = mod(obj.numEpochsQueued, obj.contrastNSteps) + 1;
            end
            
            %get current contrast
            obj.contrast = obj.contrastValues(contrastValInd);
            %disp(['contrast signal = ' num2str(obj.contrast)]);
            obj.intensity = obj.intensityValues(contrastValInd);
            %disp(['intensity = ' num2str(obj.intensity)]);
            epoch.addParameter('contrast', obj.contrast);
            epoch.addParameter('intensity', obj.intensity); 
        end
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                                    
            spot = Ellipse();
            spot.radiusX = round(obj.spotSize / 2 / obj.rigConfig.micronsPerPixel); %convert to pixels
            spot.radiusY = spot.radiusX;
            spot.color = obj.intensity;
            spot.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            presentation.addStimulus(spot);
            
            function opacity = onDuringStim(state, preTime, stimTime)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    opacity = 1;
                else
                    opacity = 0;
                end
            end
            
            presentation.addController(spot, 'opacity', @(s)onDuringStim(s, obj.preTime, obj.stimTime));
            
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
  
        function minContrast = get.minContrast(obj)
            ex = linspace(0,obj.maxContrast,obj.contrastNSteps+1);
            temp = obj.maxContrast * (10.^ex - 1) / (10^obj.maxContrast - 1);
            minContrast = temp(2);
        end
        
        function pn = parameterNames(obj, includeConstant)
            if nargin == 1
                pn = parameterNames@StageProtocol(obj);
            else
                pn = parameterNames@StageProtocol(obj, includeConstant);
            end
            
            % Force 8 bit for contrast response function
            pn = pn(~strncmp(pn, 'bitDepth', 8));
        end
        
    end
    
end