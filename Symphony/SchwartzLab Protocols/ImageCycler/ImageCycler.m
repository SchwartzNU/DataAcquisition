classdef ImageCycler < StageProtocol
    
    properties (Constant)
        identifier = 'edu.northwestern.SchwartzLab.ImageCyler'
        version = 1
        displayName = 'Image Cycler'
    end
    
    properties
        amp
        
        %times in ms
        preTime = 500 %will be rounded to account for frame rate
        stimTime = 500 %will be rounded to account for frame rate
        tailTime = 500 %will be rounded to account for frame rate
        
        maskSize = 500 %um
        
        configFile = 'textureMatrixConfig';        
    end
    
    properties
        numberOfAverages = uint16(10)
        %interpule interval in s
        interpulseInterval = 0
    end
    
    properties (Dependent)
       Nconditions 
    end
    
    properties (Constant, Hidden)
       imagesDir = 'C:\Users\Greg\Documents\Matlab\Symphony\StimulusImages\';               
    end
    
    properties (Hidden)
        imageName
        imageParams
        Nparams %max 3
        paramLen
        config
        orderOfImages
    end
            
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@StageProtocol(obj, parameterName);
            
            % Return properties for the specified parameter (see ParameterProperty class).
            switch parameterName
                case 'interpulseInterval'
                    p.units = 's';
                case 'maskSize'
                    p.displayTab = 'mostUsed';
                    p.units = 'um';   
                case {'Nconditions', 'configFile'}
                    p.displayTab = 'mostUsed';
                case 'meanLevel'
                    p.defaultValue = 0.5;
            end
        end
        
        
        function prepareRun(obj)
            global DEMO_MODE;
            % Call the base method.
            prepareRun@StageProtocol(obj);
            
            %For randomization... (Adam 10/15/15)
            obj.orderOfImages = 1:obj.Nconditions;
            
            %figure out configuration from configFile
            load(obj.configFile, 'config');
            obj.config = config;
            obj.imageParams = obj.config.conditionOrder;
            obj.Nparams = length(obj.imageParams);
            for i=1:obj.Nparams
                obj.paramLen(i) = length(obj.config.(obj.imageParams{i}));
            end
            
            if ~DEMO_MODE
                % Open figures showing the mean response of the amp.
                if strcmp(obj.ampMode, 'Whole cell')
                    obj.openFigure('Mean Response', obj.amp, 'GroupByParams', obj.imageParams, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Whole cell')
                        obj.openFigure('Mean Response', obj.amp2, 'GroupByParams', obj.imageParams, 'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, 'LineColor', 'r');
                    end
                end
                
                %PSTH figure
                if strcmp(obj.ampMode, 'Cell attached')
                    obj.openFigure('PSTH', obj.amp, 'GroupByParams', obj.imageParams,'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                        'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold);
                end
                if ~isempty(obj.amp2)
                    if strcmp(obj.amp2Mode, 'Cell attached')
                        obj.openFigure('PSTH', obj.amp2, 'GroupByParams', obj.imageParams,'StartTime', obj.stimStart, 'EndTime', obj.stimEnd, ...
                            'SpikeDetectorMode', obj.spikeDetection, 'SpikeThreshold', obj.spikeThreshold, ...
                            'LineColor', 'r');
                    end
                end
            end
        end
        
         function prepareEpoch(obj, epoch)
            % Call the base method.
            prepareEpoch@StageProtocol(obj, epoch);
            
            if mod(obj.numEpochsQueued, obj.Nconditions) == 0
               obj.orderOfImages = obj.orderOfImages(randperm(obj.Nconditions)); 
            end
            
            linearInd = obj.orderOfImages( mod(obj.numEpochsQueued, obj.Nconditions) + 1 );
            if obj.Nparams == 1
                obj.imageName = [obj.config.baseName '_' linearInd '.png'];
                epoch.addParameter(obj.imageParams{1}, obj.config.(obj.imageParams{1})(linearInd)); 
            elseif obj.Nparams == 2
                [b,a] = ind2sub(obj.paramLen,linearInd);
                obj.imageName = [obj.config.baseName '_' num2str(a) '_' num2str(b) '.png'];
                epoch.addParameter(obj.imageParams{1}, obj.config.(obj.imageParams{1})(a)); 
                epoch.addParameter(obj.imageParams{2}, obj.config.(obj.imageParams{2})(b)); 
                disp(['Adding ' obj.imageParams{1} ' = ' num2str(obj.config.(obj.imageParams{1})(a))]);
                disp(['Adding ' obj.imageParams{2} ' = ' num2str(obj.config.(obj.imageParams{2})(b))]);
            elseif obj.Nparams == 3
                [c,b,a] = ind2sub(obj.paramLen,linearInd);
                obj.imageName = [obj.config.baseName '_' num2str(a) '_' num2str(b) '_' num2str(c) '.png'];
                epoch.addParameter(obj.imageParams{1}, obj.config.(obj.imageParams{1})(a)); 
                epoch.addParameter(obj.imageParams{2}, obj.config.(obj.imageParams{2})(b)); 
                epoch.addParameter(obj.imageParams{3}, obj.config.(obj.imageParams{3})(c)); 
            else
                disp('Error: more than 3 parameters varied in config file');
            end
            
        end
        
        
        function preparePresentation(obj, presentation)
            %set bg
            obj.setBackground(presentation);
                          
            curImage = imread(fullfile(obj.imagesDir, obj.imageName)); 
            im = Image(curImage);
            
            if fliplr(size(curImage)) ~= obj.windowSize
                disp('Error: images must be 1140 x 912 pixels');
            end;
            im.size = obj.windowSize; %images must be 1140 x 912
            im.position = [obj.windowSize(1)/2, obj.windowSize(2)/2];
            presentation.addStimulus(im);
            
            maskSize_pix = obj.maskSize/obj.rigConfig.micronsPerPixel;
            maskSize_frac = maskSize_pix / obj.windowSize(2);
            mask = Mask.createCircularAperture(maskSize_frac);
            im.setMask(mask);
            
            function opacity = onDuringStim(state, preTime, stimTime)
                if state.time>preTime*1e-3 && state.time<=(preTime+stimTime)*1e-3
                    opacity = 1;
                else
                    opacity = 0;
                end
            end
            
            controller = PropertyController(im, 'opacity', @(s)onDuringStim(s, obj.preTime, obj.stimTime));
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
            %figure out configuration from configFile
            load(obj.configFile, 'config');
            imageParams = config.conditionOrder;
            Nconditions = 1;
            for i=1:length(imageParams)
                Nconditions = Nconditions * length(config.(imageParams{i}));
            end
        end
        
    end
    
end