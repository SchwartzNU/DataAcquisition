classdef SpotsRFFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Spots RF'
    end
    
    properties
        deviceName
        stimStart %data point
        stimEnd %data point
        Xvals = []
        Yvals = []
        responseMean = []
        responseVals = {}
        responseVals_unNorm = {};
        responseN = []
        responseSEM = []
        responseType %only for whole-cell for now, spikes are always just counted minus baseline
        responseUnits
        mode
        plotHandle
        
        %analysis params
        lowPassFreq
        spikeThreshold
        spikeDetectorMode
    end
    
    properties (Hidden)
        baselineRate = 0;
        Ntrials = 0 ;%for baseline rate calculation
    end
    
    
    methods
        
        function obj = SpotsRFFigureHandler(protocolPlugin, deviceName, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParamValue('StartTime', 0, @(x)isnumeric(x));
            ip.addParamValue('EndTime', 0, @(x)isnumeric(x));
            ip.addParamValue('Mode', 'Cell attached', @(x)ischar(x));
            ip.addParamValue('ResponseType', '', @(x)ischar(x));
            ip.addParamValue('LowPassFreq', 100, @(x)isnumeric(x));
            ip.addParamValue('SpikeThreshold', 10, @(x)isnumeric(x));
            ip.addParamValue('SpikeDetectorMode', 'Stdev', @(x)ischar(x));
            
            % Allow deviceName to be an optional parameter.
            % inputParser.addOptional does not fully work with string variables.
            if nargin > 1 && any(strcmp(deviceName, ip.Parameters))
                varargin = [deviceName varargin];
                deviceName = [];
            end
            if nargin == 1
                deviceName = [];
            end
            
            ip.parse(varargin{:});
            
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            obj.deviceName = deviceName;
            obj.stimStart = round(ip.Results.StartTime);
            obj.stimEnd = round(ip.Results.EndTime);
            obj.mode = ip.Results.Mode;
            obj.responseType = ip.Results.ResponseType;
            obj.lowPassFreq = ip.Results.LowPassFreq;
            obj.spikeThreshold = ip.Results.SpikeThreshold;
            obj.spikeDetectorMode = ip.Results.SpikeDetectorMode;
            
            %set default response type
            if strcmp(obj.mode, 'Cell attached') && isempty(obj.responseType)
                obj.responseType = 'Spike count';
            elseif strcmp(obj.mode, 'Whole cell') && isempty(obj.responseType)
                obj.responseType = 'Charge';
            end
            
            if ~isempty(obj.deviceName)
                set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            end
            
            xlabel(obj.axesHandle(), 'sec');
            set(obj.axesHandle(), 'XTickMode', 'auto');
            
            %remove menubar
            set(obj.figureHandle, 'MenuBar', 'none');
            %make room for labels
            set(obj.axesHandle(), 'Position',[0.14 0.18 0.72 0.72])
            
            obj.resetPlots();
        end
        
        
        function handleEpoch(obj, epoch)
            %focus on correct figure
            set(0, 'CurrentFigure', obj.figureHandle);
            
            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, units] = epoch.response();
            else
                [responseData, sampleRate, units] = epoch.response(obj.deviceName);
            end
            
            if strcmp(obj.mode, 'Cell attached')
                %getSpikes
                if strcmp(obj.spikeDetectorMode, 'Simple threshold')
                    responseData = responseData - mean(responseData);
                    sp = getThresCross(responseData,obj.spikeThreshold,sign(obj.spikeThreshold));
                else
                    spikeResults = SpikeDetector_simple(responseData,1./sampleRate, obj.spikeThreshold);
                    sp = spikeResults.sp;
                end
                switch obj.responseType
                    case 'Spike count'
                        %count spikes in stimulus interval
                        spikeCount = length(find(sp>=obj.stimStart & sp<obj.stimEnd));
                        %subtract baseline
                        baselineSpikes = length(find(sp<obj.stimStart));
                        stimIntervalLen = obj.stimEnd - obj.stimStart;
                        curBaseline =  baselineSpikes / (obj.stimStart / sampleRate); %Hz
                        stimSpikeRate = spikeCount / (stimIntervalLen / sampleRate); %Hz
                        if obj.Ntrials == 0
                            obj.baselineRate = curBaseline;
                        else
                            obj.baselineRate = (obj.baselineRate * (obj.Ntrials) + curBaseline) / (obj.Ntrials+1);
                        end
                        obj.Ntrials = obj.Ntrials + 1;
                        stimRate = stimSpikeRate;
                        responseVal = stimRate; %recalculated below
                        obj.responseUnits = 'spikes (norm)';
                end
                
            else
                stimData = responseData(obj.stimStart:obj.stimEnd);
                baselineData = responseData(1:obj.stimStart-1);
                stimIntervalLen = obj.stimEnd - obj.stimStart;
                switch obj.responseType
                    case 'Peak current'
                        stimData = stimData - mean(baselineData);
                        stimData = LowPassFilter(stimData,obj.lowPassFreq,1/sampleRate);
                        responseVal = max(abs(max(stimData)), abs(min(stimData)));
                        obj.responseUnits = 'pA';
                    case 'Charge'
                        responseVal = sum(stimData - mean(baselineData)) * stimIntervalLen / sampleRate;
                        obj.responseUnits = 'pC';
                end
            end
            
            %add data to the appropriate mean structure
            posX = epoch.getParameter('curShiftX');
            posY = epoch.getParameter('curShiftY');
            ind = find(obj.Xvals == posX & obj.Yvals == posY);
            if isempty(ind) %first epoch of this value
                ind = length(obj.Xvals)+1;
                obj.Xvals(ind) = posX;
                obj.Yvals(ind) = posY;
                obj.responseMean(ind) = responseVal;
                obj.responseN(ind) = 1;
                obj.responseVals{ind} = responseVal;
                if strcmp(obj.responseType, 'Spike count')
                    obj.responseVals_unNorm{ind} = stimRate;
                end
                obj.responseSEM(ind) = 0;
            else
                obj.responseN(ind) = obj.responseN(ind) + 1;
                %cumulative baseline normalization for spike counts
                if strcmp(obj.responseType, 'Spike count')
                    obj.responseVals_unNorm{ind} = [obj.responseVals_unNorm{ind}, stimRate];
                    for i=1:length(obj.responseVals_unNorm)
                        obj.responseVals{i} = obj.responseVals_unNorm{i} ./ obj.baselineRate;
                        obj.responseMean(i) = mean(obj.responseVals{i});
                        obj.responseSEM(i) = std(obj.responseVals{i})./sqrt(obj.responseN(i));
                    end
                else
                    obj.responseVals{ind} = [obj.responseVals{ind}, responseVal];
                    obj.responseMean(ind) = mean(obj.responseVals{ind});
                    obj.responseSEM(ind) = std(obj.responseVals{ind})./sqrt(obj.responseN(ind));
                end
            end
            
            %make plot
            obj.plotHandle = scatter(obj.Xvals, obj.Yvals, 70, obj.responseMean, 'fill');
            set(obj.plotHandle, 'Parent', obj.axesHandle());
            colorbar;            
            title(obj.axesHandle, ['Spots RF map: ' obj.deviceName]);            
        end
        
%         function saveFigureData(obj,fname)
%         
%         end
        
        function clearFigure(obj)
            obj.resetPlots();
            
            clearFigure@FigureHandler(obj);
        end
        
        function resetPlots(obj)
            obj.plotHandle = [];
            obj.Xvals = [];
            obj.Yvals = [];
            obj.responseMean = [];
            obj.responseVals = {};
            obj.responseN = [];
            obj.responseSEM = [];
        end
        
    end
    
end