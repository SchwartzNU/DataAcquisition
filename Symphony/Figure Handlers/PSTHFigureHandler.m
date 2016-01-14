% Property Descriptions:
%
% LineColor (ColorSpec)
%   Color of the mean response line. The default is blue.
%
% GroupByParams (string | cell array of strings)
%   List of epoch parameters whose values are used to group mean responses. The default is all current epoch parameters.

classdef PSTHFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'PSTH'
    end
    
    properties
        deviceName
        lineColor
        stimStart
        stimEnd
        binWidth
        meanPlots   % array of structures to store the properties of each class of epoch.
        meanParamNames
        splot = []; %handles for subplots
        plotRows = [];
        plotCols = [];
        storedSampleRate;
        spikeTimes = {};
        
        %analysis params
        spikeThreshold
        spikeDetectorMode
        storeSpikeTimes % boolean number
    end
    
    methods
        
        function obj = PSTHFigureHandler(protocolPlugin, deviceName, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParamValue('LineColor', 'b', @(x)ischar(x) || isvector(x));
            ip.addParamValue('GroupByParams', {}, @(x)iscell(x) || ischar(x));
            ip.addParamValue('BinWidth', 5, @(x)isnumeric(x));
            ip.addParamValue('StartTime', 0, @(x)isnumeric(x));
            ip.addParamValue('EndTime', 0, @(x)isnumeric(x));
            ip.addParamValue('SpikeThreshold', 10, @(x)isnumeric(x));
            ip.addParamValue('SpikeDetectorMode', 'Stdev', @(x)ischar(x));
            ip.addParamValue('StoreSpikeTimes', 0, @(x)isnumeric(x));
            
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
            obj.binWidth = ip.Results.BinWidth;
            obj.stimStart = ip.Results.StartTime;
            obj.stimEnd = ip.Results.EndTime;
            obj.spikeThreshold = ip.Results.SpikeThreshold;
            obj.spikeDetectorMode = ip.Results.SpikeDetectorMode;
            obj.storeSpikeTimes = ip.Results.StoreSpikeTimes;
            
            if iscell(ip.Results.GroupByParams)
                obj.meanParamNames = ip.Results.GroupByParams;
            else
                obj.meanParamNames = {ip.Results.GroupByParams};
            end
            
            if ~isempty(obj.deviceName)
                set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            end
            
            xlabel(obj.axesHandle(), 'sec');
            set(obj.axesHandle(), 'XTickMode', 'auto');
            
            obj.resetPlots();
        end
        
        
        function handleEpoch(obj, epoch)
            %focus on correct figure
            set(0, 'CurrentFigure', obj.figureHandle);
            
            %figure out subplot rows and columns if this is first epoch
            %(those fields are empty)
            if isempty(obj.plotRows)
                if epoch.containsParameter('Nconditions');
                    N = epoch.getParameter('Nconditions');
                    obj.plotRows = round(sqrt(N));
                    obj.plotCols = ceil(N/obj.plotRows);
                end
            end
            
            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, units] = epoch.response();
            else
                [responseData, sampleRate, units] = epoch.response(obj.deviceName);
            end
            
            obj.storedSampleRate = sampleRate; %for saving data
            
            %getSpikes
            if strcmp(obj.spikeDetectorMode, 'Simple threshold')
                responseData = responseData - mean(responseData);
                sp = getThresCross(responseData,obj.spikeThreshold,sign(obj.spikeThreshold));
            else
                spikeResults = SpikeDetector_simple(responseData,1./sampleRate, obj.spikeThreshold);
                sp = spikeResults.sp;
            end
            
            
            % Get the parameters for this "class" of epoch.
            % An epoch class is defined by a set of parameter values.
            if isempty(obj.meanParamNames)
                % Automatically detect the set of parameters.
                epochParams = obj.protocolPlugin.epochSpecificParameters(epoch);
            else
                % The protocol has specified which parameters to use.
                for i = 1:length(obj.meanParamNames)
                    epochParams.(obj.meanParamNames{i}) = epoch.getParameter(obj.meanParamNames{i});
                end
            end
            
%             sp = 10000 * 1.5* sort(rand(100,1));
%             sp = .3 + 1 * 10000 * sort(rand(epoch.getParameter('curSpotSize'),1));
            
            % Check if we have existing data for this class of epoch.
            %disp(epochParams)
            meanPlot = struct([]);
            for i = 1:numel(obj.meanPlots)
                if isequal(obj.meanPlots(i).params, epochParams)
                    meanPlot = obj.meanPlots(i);
                    plotIndex = i;
                    break;
                end
            end
            
            if isempty(meanPlot)
                % This is the first epoch of this class to be plotted.
                % make subplots
                L = length(obj.meanPlots)+1;
                %cla(obj.axesHandle());
                %obj.splot = [];
%                 for i=1:L
%                     if isempty(obj.plotRows)
%                         obj.splot(i) = subplot(L,1,i,'replace','Parent',obj.figureHandle);
%                     else
%                         obj.splot(i) = subplot(obj.plotRows,obj.plotCols,i,'replace','Parent',obj.figureHandle);
%                     end
%                     hold(obj.splot(i),'on');
%                     if i<L
%                         curPlot = obj.meanPlots(i);
%                         curPlot.plotHandle = plot(obj.splot(i),curPlot.bins / curPlot.sampleRate, curPlot.data, 'Color', obj.lineColor);
%                         curPlot.lstart = line('Xdata', [obj.stimStart obj.stimStart] / curPlot.sampleRate, ...
%                             'Ydata', [0 max(curPlot.data)], ...
%                             'Color', 'k', 'LineStyle', '--');
%                         curPlot.lend = line('Xdata', [obj.stimEnd obj.stimEnd] / curPlot.sampleRate, ...
%                             'Ydata', [0 max(curPlot.data)], ...
%                             'Color', 'k', 'LineStyle', '--');
%                         set(curPlot.lstart,'Parent',obj.splot(i));
%                         set(curPlot.lend,'Parent',obj.splot(i));
%                     end
%                 end
                
                %get bins
                samplesPerMS = sampleRate/1E3;
                samplesPerBin = obj.binWidth*samplesPerMS;
                bins = 0:samplesPerBin:length(responseData);
                
                %compute PSTH for this epoch
                spCount = histc(sp,bins);
                if isempty(spCount)
                    spCount = zeros(1,length(bins));
                end
                
                %convert to Hz
                spCount = spCount / (obj.binWidth*1E-3);
                units = 'Hz';
                
                meanPlot = {};
                meanPlot.params = epochParams;
                meanPlot.data = spCount;
                meanPlot.bins = bins';
                meanPlot.sampleRate = sampleRate;
                meanPlot.units = units;
                meanPlot.count = 1;
                hold(obj.axesHandle(), 'on');
                meanPlot.plotHandle = {};%plot(obj.splot(L),meanPlot.bins / sampleRate, meanPlot.data, 'Color', obj.lineColor);
%                 %put in start and end lines
                meanPlot.lstart = {};%line('Xdata', [obj.stimStart obj.stimStart] / sampleRate, ...
%                     'Ydata', [0 max(meanPlot.data)], ...
%                     'Color', 'k', 'LineStyle', '--');
                meanPlot.lend = {};%line('Xdata', [obj.stimEnd obj.stimEnd] / sampleRate, ...
%                     'Ydata', [0 max(meanPlot.data)], ...
%                     'Color', 'k', 'LineStyle', '--');
%                 set(meanPlot.lstart,'Parent',obj.splot(L));
%                 set(meanPlot.lend,'Parent',obj.splot(L));
                
%                 a = obj.meanPlots;
%                 save meanPlot
%                 save a

                obj.meanPlots(end + 1) = meanPlot;
                
                
            else
                % This class of epoch has been seen before, add the current response to the mean.
                % TODO: Adjust response data to the same sample rate and unit as previous epochs if needed.
                % TODO: if the length of data is varying then the mean will not be correct beyond the min length.
                %compute PSTH for this epoch
                
                spCount = histc(sp,meanPlot.bins);
                if isempty(spCount)
                    spCount = zeros(1,length(meanPlot.bins));
                end
                
                %convert to Hz
                spCount = spCount / (obj.binWidth*1E-3);
                
                meanPlot.data = (meanPlot.data * meanPlot.count + spCount) / (meanPlot.count + 1);
                meanPlot.count = meanPlot.count + 1;
%                 if ishandle(meanPlot.plotHandle) %check for valid handle
%                     set(meanPlot.plotHandle, 'XData',  meanPlot.bins / sampleRate, ...
%                         'YData', meanPlot.data);
%                     set(meanPlot.lstart, 'Ydata',  [0 max(meanPlot.data)]);
%                     set(meanPlot.lend, 'Ydata',  [0 max(meanPlot.data)]);
%                 else
%                     hold(obj.splot(plotIndex), 'off');
%                     meanPlot.plotHandle = plot(obj.splot(plotIndex),meanPlot.bins / sampleRate, meanPlot.data, 'Color', obj.lineColor);
%                     hold(obj.splot(plotIndex), 'on');
%                     %put in start and end lines
%                     meanPlot.lstart = line('Xdata', [obj.stimStart obj.stimStart] / sampleRate, ...
%                         'Ydata', [0 max(meanPlot.data)], ...
%                         'Color', 'k', 'LineStyle', '--');
%                     meanPlot.lend = line('Xdata', [obj.stimEnd obj.stimEnd] / sampleRate, ...
%                         'Ydata', [0 max(meanPlot.data)], ...
%                         'Color', 'k', 'LineStyle', '--');
%                     set(meanPlot.lstart,'Parent',obj.splot(plotIndex));
%                     set(meanPlot.lend,'Parent',obj.splot(plotIndex));
%                 end
                obj.meanPlots(i) = meanPlot;
            end
            
%             clf;

            % order the meanPlots by meanPlot.params value
            param_by_plot = zeros(numel(obj.meanPlots),1);
            paramNames = fieldnames(epochParams);
            sortParam = paramNames{1};
            % some protocols don't have split PSTH plots, so detect that
            % and set them all to subplot 1
            if isempty(obj.meanParamNames)
                plotOrder = ones(numel(obj.meanPlots),1);
            else
                for k = 1:numel(obj.meanPlots)
                    param_by_plot(k) = obj.meanPlots(k).params.(sortParam);
                end
                [~,plotOrder] = sort(param_by_plot);
            end
            
            if isempty(epochParams)
                titleString = 'All epochs grouped together.';
            else
                paramNames = fieldnames(epochParams);
                titleString = ['Grouped by ' humanReadableParameterName(paramNames{1})];
                for i = 2:length(paramNames) - 1
                    titleString = [titleString ', ' humanReadableParameterName(paramNames{i})];
                end
                if length(paramNames) > 1
                    titleString = [titleString ' and ' humanReadableParameterName(paramNames{end})];
                end
            end
            
            
            % actually plot the figures
            clf(obj.figureHandle)
            ha = tight_subplot(length(obj.meanPlots),1);
            for k = 1:numel(obj.meanPlots)
                plotIndex = plotOrder(k);
                meanPlot = obj.meanPlots(plotIndex);
                obj.splot(plotIndex) = ha(k);%= subplot(,k,'replace','Parent',obj.figureHandle);
                
                if k == 1
                    title(obj.splot(plotIndex), titleString);
                end
                
                hold(obj.splot(plotIndex), 'off');
%                 meanPlot.plotHandle = plot(obj.splot(plotIndex), 1:10);
                plot(obj.splot(plotIndex),meanPlot.bins / sampleRate, meanPlot.data, 'Color', obj.lineColor);
                hold(obj.splot(plotIndex), 'on');
                %put in start and end lines
                lstart = line('Xdata', [obj.stimStart obj.stimStart] / sampleRate, ...
                    'Ydata', [0 max(meanPlot.data)], ...
                    'Color', 'k', 'LineStyle', '--');
                lend = line('Xdata', [obj.stimEnd obj.stimEnd] / sampleRate, ...
                    'Ydata', [0 max(meanPlot.data)], ...
                    'Color', 'k', 'LineStyle', '--');
                set(lstart,'Parent',obj.splot(plotIndex));
                set(lend,'Parent',obj.splot(plotIndex));
                ylabel(num2str(round(meanPlot.params.(sortParam))));
                if k ~= numel(obj.meanPlots)
                    set(gca, 'XTickLabel', '');
                end
            end
            
            
            % Update the y axis with the units of the response.
%             ylabel(obj.splot(1), 'Spike rate (Hz)');
%             ylabel(obj.splot(i), i);
%             xlabel(obj.splot(1), 'Time (s)');
            
            %set scale to be the same for all y axes
            L = length(obj.meanPlots);
            minVec = zeros(1,L);
            maxVec = zeros(1,L);
            for i=1:L
                minVec(i) = min(obj.meanPlots(i).data);
                maxVec(i) = max(obj.meanPlots(i).data);
            end
            minVal = min(minVec);
            maxVal = max(maxVec);
            if minVal==maxVal
                minVal = -1;
                maxVal = 1;
            end
            for i=1:L
                set(obj.splot(i),'ylim',[minVal, maxVal]);
            end
            
            if obj.storeSpikeTimes
                obj.spikeTimes{length(obj.spikeTimes)+1,1} = sp;
            end
        end
        
        function saveFigureData(obj,fname)
            L = length(obj.meanPlots);
            data.Xvals = cell(1,L);
            data.Yvals = cell(1,L);
            for i=1:L
                data.epochParams{i} = obj.meanPlots(i).params;
                data.Xvals{i} = obj.meanPlots(i).bins / obj.storedSampleRate;
                data.Yvals{i} = obj.meanPlots(i).data;
            end
            data.spikeDetectorMode = obj.spikeDetectorMode;
            data.spikeThreshold = obj.spikeThreshold;  
            data.startTime = obj.stimStart;
            data.endTime = obj.stimEnd;
            data.sampleRate = obj.storedSampleRate;
            %write image
            saveas(obj.figureHandle,fname,'pdf');
            save(fname,'data');
        end
        
        function clearFigure(obj)
            obj.resetPlots();
            
            clearFigure@FigureHandler(obj);
        end
        
        
        function resetPlots(obj)
            obj.meanPlots = struct('params', {}, ...        % The params that define this class of epochs.
                'data', {}, ...          % The mean of all responses of this class.
                'bins', [], ...          % PSTH bins
                'sampleRate', {}, ...    % The sampling rate of the mean response.
                'units', {}, ...         % The units of the mean response.
                'count', {}, ...         % The number of responses used to calculate the mean reponse.
                'plotHandle', {}, ...    % The handle of the plot for the mean response of this class.
                'lstart', {}, ...        % Stim start line
                'lend', {});             % Stim end line
            obj.splot = [];
            plotRows = [];
            plotCols = [];
        end
        
    end
    
end