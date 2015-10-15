% Property Descriptions:
%
% LineColor (ColorSpec)
%   Color of the mean response line. The default is blue.
%
% GroupByParams (string | cell array of strings)
%   List of epoch parameters whose values are used to group mean responses. The default is all current epoch parameters.

classdef SpatialResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Spatial Response'
    end
    
    properties
        deviceName
        spacePlot
        epochIndex
        positions
        responseValues
        responseUnits
        stimStart
        stimEnd
        spikeThreshold
        spikeDetectorMode
        Ntrials
        baselineRate
    end
    
    methods
        
        function obj = SpatialResponseFigureHandler(protocolPlugin, deviceName, varargin)           
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParamValue('StartTime', 0, @(x)isnumeric(x));
            ip.addParamValue('EndTime', 0, @(x)isnumeric(x));
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
            obj.epochIndex = 0;
            obj.stimStart = ip.Results.StartTime;
            obj.stimEnd = ip.Results.EndTime;
            obj.spikeThreshold = ip.Results.SpikeThreshold;
            obj.spikeDetectorMode = ip.Results.SpikeDetectorMode;
            obj.Ntrials = 0;
            
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
                [responseData, sampleRate, units] = epoch.response();
            else
                [responseData, sampleRate, units] = epoch.response(obj.deviceName);
            end

            
            % detect spikes
            if strcmp(obj.spikeDetectorMode, 'Simple threshold')
                responseData = responseData - mean(responseData);
                sp = getThresCross(responseData,obj.spikeThreshold,sign(obj.spikeThreshold));
            else
                spikeResults = SpikeDetector_simple(responseData,1./sampleRate, obj.spikeThreshold);
                sp = spikeResults.sp;
            end


            obj.positions = reshape(str2num(char(epoch.getParameter('positions'))), [], 2);
%             disp(obj.positions)
            
%             responseVal = max(0, random('unid', 50) + sqrt(2*80^2) - sqrt((X-50)^2 + (Y-50)^2))/10.0;
%             responseVal = 1 - (sqrt((X-30)^2 + (Y-30)^2)) / 100;
            
            spotTotalTime = epoch.getParameter('spotTotalTime');
            numSpots = epoch.getParameter('numSpots');
            responseDelay = epoch.getParameter('responseDelay');
                       
%             sp = 10000 * (spotTotalTime * numSpots) * rand(100,1);
            
            sp = sp ./ 10000;

            obj.responseValues = zeros(numSpots, 1);
            for si = 1:numSpots
                t_range = obj.stimStart / 10000 + responseDelay / 1000 + spotTotalTime * [(si - 1), si];
                obj.responseValues(si,1) = sum(sp > t_range(1) & sp < t_range(2));
            end
            
            if size(obj.positions, 1) >= 3
                
                xlist = obj.positions(:,1);
                ylist = obj.positions(:,2);
                zlist = obj.responseValues;
                                
%                 obj.spacePlot = struct([]);
                X = linspace(min(xlist), max(xlist), 40);
                Y = linspace(min(ylist), max(ylist), 40);
    % 
    %             responseMesh = zeroes(
    %             obj.spacePlot.plotHandle = 
    %             plot(obj.axesHandle(), obj.positions(:,1) + obj.positions(:,2), obj.responseValues);

                
                [xq,yq] = meshgrid(X, Y);
                vq = griddata(xlist, ylist, zlist, xq, yq);
                surf(obj.axesHandle(), xq, yq, vq, 'EdgeColor', 'none', 'FaceColor', 'interp');
                hold on
                plot3(xlist,ylist,zlist,'o');
                hold off
                view(obj.axesHandle(), 0, 90)
                xlabel(obj.axesHandle(),'X (um)');
                ylabel(obj.axesHandle(),'Y (um)');
                axis equal
                colorbar
                
                masses = zlist .^ 2;
                centerOfMassXY = [sum(xlist .* masses)/sum(masses), sum(ylist .* masses)/sum(masses)];
                title(obj.axesHandle(),['center of mass: ' num2str(centerOfMassXY)])                
            end
%             obj.spacePlot.plotHandle = imagsc(obj.axesHandle(), xq, yq, vq);
%             if isempty(spacePlot)
%                 % This is the first epoch of this class to be plotted.
%                 spacePlot = {};
%                 spacePlot.params = epochParams;
%                 spacePlot.data = responseData;
%                 spacePlot.units = units;
%                 spacePlot.count = 1;
%                 hold(obj.axesHandle(), 'on');
%                 spacePlot.plotHandle = plot(obj.axesHandle(), (1:length(spacePlot.data)) / sampleRate, spacePlot.data, 'Color', obj.lineColor);
%                 obj.spacePlots(end + 1) = spacePlot;
%             else
%                 spacePlot.data = (spacePlot.data * spacePlot.count + responseData) / (spacePlot.count + 1);
%                 spacePlot.count = spacePlot.count + 1;
%                 set(spacePlot.plotHandle, 'XData', (1:length(spacePlot.data)) / sampleRate, ...
%                                          'YData', spacePlot.data);
%             end
            

        end
        
        
        function clearFigure(obj)
            obj.resetPlots();
            
            clearFigure@FigureHandler(obj);
        end
        
        
        function resetPlots(obj)
            obj.positions = [];
            obj.responseValues = [];
            obj.epochIndex = 0;
            obj.spacePlot = struct([]);
%                                    'params', {}, ...        % The params that define this class of epochs.
%                                    'data', {}, ...          % The mean of all responses of this class.
%                                    'sampleRate', {}, ...    % The sampling rate of the mean response.
%                                    'units', {}, ...         % The units of the mean response.
%                                    'count', {}, ...         % The number of responses used to calculate the mean reponse.
%                                    'plotHandle', {});       % The handle of the plot for the mean response of this class.
        end
        
    end
    
end