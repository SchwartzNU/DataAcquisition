% Property Descriptions:
%
% LineColor (ColorSpec)
%   Color of the mean response line. The default is blue.
%
% GroupByParams (string | cell array of strings)
%   List of epoch parameters whose values are used to group mean responses. The default is all current epoch parameters.

classdef ShapeResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Shape Response'
    end
    
    properties
        deviceName
        epochIndex
        stimStart
        stimEnd
        spikeThreshold
        spikeDetectorMode
        Ntrials
        baselineRate
        
        analysisData
        epochData
        shapePlotMode
    end
    
    methods
        
        function obj = ShapeResponseFigureHandler(protocolPlugin, deviceName, varargin)           
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParamValue('StartTime', 0, @(x)isnumeric(x));
            ip.addParamValue('EndTime', 0, @(x)isnumeric(x));
            ip.addParamValue('SpikeThreshold', 10, @(x)isnumeric(x));
            ip.addParamValue('SpikeDetectorMode', 'Stdev', @(x)ischar(x));
            ip.addParamValue('shapePlotMode', 'plotSpatial_mean', @(x)ischar(x));
            
            
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
            obj.epochIndex = 0;
            obj.stimStart = ip.Results.StartTime;
            obj.stimEnd = ip.Results.EndTime;
            obj.spikeThreshold = ip.Results.SpikeThreshold;
            obj.spikeDetectorMode = ip.Results.SpikeDetectorMode;
            obj.Ntrials = 0;
            obj.shapePlotMode = ip.Results.shapePlotMode;
           
            if ~isempty(obj.deviceName)
                set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            end 
                  
            %remove menubar
%             set(obj.figureHandle, 'MenuBar', 'none');
            %make room for labels
            set(obj.axesHandle(), 'Position',[0.14 0.18 0.72 0.72])
            title(obj.axesHandle(), 'Waiting for results');
            
            obj.resetPlots();
        end
        
        
        function handleEpoch(obj, epoch)
                       
            %focus on correct figure
            set(0, 'CurrentFigure', obj.figureHandle);
            obj.epochIndex = obj.epochIndex + 1;
                       
            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, ~] = epoch.response();
            else
                [responseData, sampleRate, ~] = epoch.response(obj.deviceName);
            end
            
            % detect spikes
            if strcmp(obj.spikeDetectorMode, 'Simple threshold')
                responseData = responseData - mean(responseData);
                sp = getThresCross(responseData,obj.spikeThreshold,sign(obj.spikeThreshold));
            else
                spikeResults = SpikeDetector_simple(responseData,1./sampleRate, obj.spikeThreshold);
                sp = spikeResults.sp;
            end

            sd = ShapeData(epoch, 'online');
            global DEMO_MODE;
            
            if strcmp(sd.ampMode, 'Cell attached')
                if DEMO_MODE
                    sd.simulateSpikes();
                else
                    sd.setSpikes(sp);
                end
            else % whole cell
                if DEMO_MODE
                    sd.simulateSpikes();
                else
                    sd.setResponse(responseData');
                    sd.processWholeCell();
                end
            end
                
            obj.epochData{obj.epochIndex, 1} = sd;
                        
            obj.analysisData = processShapeData(obj.epochData);
%             disp(obj.epochData)
%             disp(obj.outputData)
%             figure(11)
            clf;
            if strcmp(obj.shapePlotMode, 'plotSpatial_mean') && obj.epochIndex == 1
                spm = 'temporalResponses';
            else
                spm = obj.shapePlotMode;
            end
            plotShapeData(obj.analysisData, spm);
        end
        
        
        function clearFigure(obj)
            obj.resetPlots();
            clearFigure@FigureHandler(obj);
        end
        
%         function od = getOutputData(obj)
%             od = obj.outputData;
%         end
        
        
        function resetPlots(obj)
            obj.analysisData = [];
            obj.epochData = {};
            obj.epochIndex = 0;
        end
        
    end
    
end