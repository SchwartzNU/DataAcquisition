classdef IVCurve < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.IVCurve'
        version = 1
        displayName = 'IV Curve'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        %mean (bg) and amplitude of pulse
        intensity = 0.1; %make it contrast instead?
        
        spotSize = 300; %microns
        
        initHoldSignal = -70; %mV
        holdSignalNSteps = 11;
        holdSignalStepSize = 10; %mV
    end
    
    properties
        numberOfAverages = uint16(5)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Dependent)
        maxHold 
    end
    
    properties (Hidden)
        holdValues
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
                case {'initHoldSignal', 'holdSignalStepSize', 'maxHold'}
                    p.units = 'mV';
                case {'ampMode', 'amp2Mode'}
                    p.defaultValue = 'Whole cell';
            end
        end

        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %set hold values
            obj.holdValues = obj.initHoldSignal:obj.holdSignalStepSize:obj.initHoldSignal+obj.holdSignalStepSize*(obj.holdSignalNSteps-1);
            obj.holdValues
            
            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                obj.openFigure('Mean Response', obj.amp, 'GroupByParams', {'ampHoldSignal'}, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                if ~isempty(obj.amp2) %TODO: what about amp 2? same signals?
                    obj.openFigure('Mean Response', obj.amp2, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                end
                
            end
        end
        
        function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            % compute hold signal       
            holdSignalInd = mod(obj.numEpochsQueued, obj.holdSignalNSteps) + 1;
            
            %get current hold signal
            obj.ampHoldSignal = obj.holdValues(holdSignalInd);
            disp(['hold signal = ' num2str(obj.ampHoldSignal)]);
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
            
            function c = onDuringStim(state, preTime, stimTime, intensity, meanLevel)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    c = intensity;
                else
                    c = meanLevel;
                end
            end
            
            presentation.addController(spot, 'color', @(s)onDuringStim(s, obj.preTime, obj.stimTime, obj.intensity, obj.meanLevel));
            
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
  
        function maxHold = get.maxHold(obj)
            maxHold = obj.initHoldSignal + (obj.holdSignalNSteps-1)*obj.holdSignalStepSize;
        end
        
        function pn = parameterNames(obj, includeConstant)
            if nargin == 1
                pn = parameterNames@StageProtocol(obj);
            else
                pn = parameterNames@StageProtocol(obj, includeConstant);
            end
            
            % Hide hold signal parameters since they are changing each
            % epoch
            pn = pn(~strncmp(pn, 'ampHoldSignal', 14));
            pn = pn(~strncmp(pn, 'amp2HoldSignal', 14));
            pn = pn(~strncmp(pn, 'ampMode', 14));
            pn = pn(~strncmp(pn, 'amp2Mode', 14));
        end
        
    end
    
end