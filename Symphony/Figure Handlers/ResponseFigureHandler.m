% Property Descriptions:
%
% LineColor (ColorSpec)
%   Color of the response line. The default is blue.

classdef ResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Response'
    end
    
    properties
        plotHandle
        deviceName
        lineColor
        stimStart
        stimEnd
        
        spikeThreshold
        spikeDetectorMode
        plotHandle_spikes
    end
    
    methods
        
        function obj = ResponseFigureHandler(protocolPlugin, deviceName, varargin)            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParamValue('LineColor', 'b', @(x)ischar(x) || isvector(x));
            ip.addParamValue('StartTime', 0, @(x)isnumeric(x));
            ip.addParamValue('EndTime', 0, @(x)isnumeric(x));
            ip.addParamValue('SpikeThreshold', 10, @(x)isnumeric(x));
            ip.addParamValue('SpikeDetectorMode', '', @(x)ischar(x));
            
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
            obj.lineColor = ip.Results.LineColor;
            obj.stimStart = ip.Results.StartTime;
            obj.stimEnd = ip.Results.EndTime;
            obj.spikeThreshold = ip.Results.SpikeThreshold;
            obj.spikeDetectorMode = ip.Results.SpikeDetectorMode;
            
            if ~isempty(obj.deviceName)
                set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            end   
                        
            obj.plotHandle = plot(obj.axesHandle(), 1:100, zeros(1, 100), 'Color', obj.lineColor);
            xlabel(obj.axesHandle(), 'sec');
            set(obj.axesHandle(), 'XTickMode', 'auto');
            
            if ~isempty(obj.spikeDetectorMode)
                hold(obj.axesHandle(), 'on')
                obj.plotHandle_spikes = plot(obj.axesHandle(), 1:100, -0.5+zeros(1, 100), 'rx');
                hold(obj.axesHandle(), 'off')
            end
            
            %remove menubar
            set(obj.figureHandle, 'MenuBar', 'none');
            %make room for labels
            set(obj.axesHandle, 'Position',[0.14 0.18 0.72 0.72])
        end
        
        
        function handleEpoch(obj, epoch)
            %focus on correct figure
            set(0, 'CurrentFigure', obj.figureHandle);
            
            % Update the figure title with the epoch number and any parameters that are different from the protocol default.
            epochParams = obj.protocolPlugin.epochSpecificParameters(epoch);
            paramsText = '';
            if ~isempty(epochParams)
                for field = sort(fieldnames(epochParams))'
                    paramValue = epochParams.(field{1});
                    if islogical(paramValue)
                        if paramValue
                            paramValue = 'True';
                        else
                            paramValue = 'False';
                        end
                    elseif isnumeric(paramValue)
                        paramValue = num2str(paramValue);
                    end
                    paramsText = [paramsText ', ' humanReadableParameterName(field{1}) ' = ' paramValue]; %#ok<AGROW>
                end
            end
            %set(get(obj.axesHandle(), 'Title'), 'String', ['Epoch #' num2str(obj.protocolPlugin.numEpochsCompleted) paramsText]);
            set(get(obj.axesHandle(), 'Title'), 'String', ['Epoch #' num2str(obj.protocolPlugin.numEpochsCompleted)]);
            
            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, units] = epoch.response();
            else
                [responseData, sampleRate, units] = epoch.response(obj.deviceName);
            end
            
%             responseData = smooth(rand(size(responseData)) + responseData, 100)*10 + 1;

            %getSpikes
            if ~isempty(obj.spikeDetectorMode)
                if strcmp(obj.spikeDetectorMode, 'Simple threshold')
                    responseData = responseData - mean(responseData);
                    sp = getThresCross(responseData,obj.spikeThreshold,sign(obj.spikeThreshold));
                else
                    spikeResults = SpikeDetector_simple(responseData,1./sampleRate, obj.spikeThreshold);
                    sp = spikeResults.sp;
                end
            end
            
%             sp = sampleRate * 1.5 * sort(rand(20,1));
            
            % Plot the response
            if isempty(responseData)
                text(0.5, 0.5, 'no response data available', 'FontSize', 12, 'HorizontalAlignment', 'center');
            else
                set(obj.plotHandle, 'XData', (1:numel(responseData))/sampleRate, ...
                                    'YData', responseData);
                
                % add spike crosses
                if ~isempty(obj.spikeDetectorMode)
                    spike_x_height = zeros(length(sp),1);
                    for si = 1:length(sp)
                        spike_x_height(si) = responseData(round(sp(si)));
                    end
                    set(obj.plotHandle_spikes, 'XData', sp / sampleRate, 'YData', spike_x_height);
                end
                                
                %add start and end lines
                %put in start and end lines
                limVec = get(obj.axesHandle(),'ylim');
                plotMin = limVec(1);
                plotMax = limVec(2);
            
                lstart = line('Xdata', [obj.stimStart obj.stimStart] / sampleRate, ...
                    'Ydata', [plotMin, plotMax], ...
                    'Color', 'k', 'LineStyle', '--');
                lend = line('Xdata', [obj.stimEnd obj.stimEnd] / sampleRate, ...
                    'Ydata', [plotMin, plotMax], ...
                    'Color', 'k', 'LineStyle', '--');
                set(lstart,'Parent',obj.axesHandle());
                set(lend,'Parent',obj.axesHandle());
                ylabel(obj.axesHandle(), units, 'Interpreter', 'none');
                xlabel(obj.axesHandle(), 'Time (s)');
                
                %auto scale
                set(obj.axesHandle(), 'ylim', [min(responseData)-.05*abs(min(responseData)), eps+max(responseData)+.05*abs(max(responseData))]);
            end
        end
        
        function saveFigureData(obj,fname)
             saveas(obj.figureHandle,fname,'pdf');
        end
        
        
        function clearFigure(obj)
            clearFigure@FigureHandler(obj);
            
            obj.plotHandle = plot(obj.axesHandle(), 1:100, zeros(1, 100), 'Color', obj.lineColor);
            
            if ~isempty(obj.spikeDetectorMode)
                hold(obj.axesHandle(), 'on')
                obj.plotHandle_spikes = plot(obj.axesHandle(), 0, 0, 'rx');
                hold(obj.axesHandle(), 'off')
            end
        end
        
    end
    
end