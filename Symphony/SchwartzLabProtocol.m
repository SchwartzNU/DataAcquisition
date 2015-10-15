classdef SchwartzLabProtocol < SymphonyProtocol
    
    properties (Abstract)
        amp
        ampHoldSignal
        amp2HoldSignal
    end
    
    properties
        ampMode
        amp2Mode
        
        %for online analysis
        startTimeOffset = 0 %ms from stimStart
        endTimeOffset = 0 %ms from stimEnd
        
        %spike mode
        spikeDetection
        spikeThreshold = 10 %uV or stds        
        amp2SpikeDetection
        amp2SpikeThreshold = 10
        
        %for whole cell
        lowPassFreq = 100 %Hz
        responseType
    end
    
    properties (Abstract, Dependent, SetAccess = private)
        % Defined as abstract to allow sub-classes control over the order of properties.
        amp2
        
        % The amp2 sub-class get method is usually:
        % function amp2 = get.amp2(obj)
        %    amp2 = obj.get_amp2();
        % end
    end
    
    methods
        
        function p = parameterProperty(obj, parameterName)
            % Call the base method to create the property object.
            p = parameterProperty@SymphonyProtocol(obj, parameterName);
            
            switch parameterName
                case 'amp'
                    p.defaultValue = obj.rigConfig.multiClampDeviceNames();
                    p.displayTab = 'amplifier';
                case 'amp2'
                    p.displayTab = 'amplifier';
                case {'ampHoldSignal', 'amp2HoldSignal'}
                    p.units = 'mV or pA';
                    p.displayTab = 'amplifier';
                case 'sampleRate'
                    p.displayTab = 'amplifier';
                case {'ampMode', 'amp2Mode'}
                    p.defaultValue = {'Cell attached', 'Whole cell'};
                    p.displayTab = 'mostUsed'; 
                case 'numberOfAverages'
                    p.displayTab = 'mostUsed'; 
                case 'responseType'
                    p.defaultValue = {'Charge', 'Peak current'};
                    p.displayTab = 'analysis';
                case 'lowPassFreq'
                    p.units = 'Hz';
                    p.displayTab = 'analysis';                    
                case {'spikeDetection', 'amp2SpikeDetection'}
                    p.defaultValue = {'Stdev', 'Simple threshold'};
                    p.displayTab = 'analysis';
                case {'spikeThreshold', 'amp2SpikeThreshold'}    
                    p.units = 'std/pA/mV';
                    p.displayTab = 'analysis';
                case {'startTimeOffset', 'endTimeOffset'}
                    p.units = 'ms';
                    p.displayTab = 'analysis';            
            end
        end
        
        
        function pn = parameterNames(obj, includeConstant)
            if nargin == 1
                pn = parameterNames@SymphonyProtocol(obj);
            else
                pn = parameterNames@SymphonyProtocol(obj, includeConstant);
            end
            
            % Hide parameters with 'amp2' prefix if the current rig config only has one amp.
            if obj.rigConfig.numMultiClampDevices() <= 1
                pn = pn(~strncmp(pn, 'amp2', 4));
            end
            
%             %show only correct analysis params
%             if (obj.rigConfig.numMultiClampDevices() <= 1 && strcmp(obj.ampMode, 'Cell attached')) ...
%                     || (strcmp(obj.ampMode, 'Cell attached') && strcmp(obj.amp2Mode, 'Cell attached'))                
%                pn = pn(~strcmp(pn, 'lowPassFreq'));
%                pn = pn(~strcmp(pn, 'responseType'));
%             end
% %             
% %             if ~strcmp(obj.ampMode, 'Cell attached')
% %                 pn = pn(~strcmp(pn, 'spikeDetectorMode'));
% %                 pn = pn(~strcmp(pn, 'spikeThreshold'));                
% %             end
% %             
% %             if obj.rigConfig.numMultiClampDevices() > 1 && ~strcmp(obj.amp2Mode, 'Cell attached')
% %                 pn = pn(~strcmp(pn, 'amp2SpikeDetectorMode'));
% %                 pn = pn(~strcmp(pn, 'amp2SpikeThreshold'));                
% %             end
        end
        
        
        function prepareRun(obj)
            prepareRun@SymphonyProtocol(obj);
            
            % Set main amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'mV');
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal, 'pA');
            end
            
            % Set secondary amp hold signal.
            if obj.rigConfig.numMultiClampDevices() > 1
                if strcmp(obj.rigConfig.multiClampMode(obj.amp2), 'VClamp')
                    obj.setDeviceBackground(obj.amp2, obj.amp2HoldSignal, 'mV');
                else
                    obj.setDeviceBackground(obj.amp2, obj.amp2HoldSignal, 'pA');
                end
            end
        end
        
        function prepareEpoch(obj, epoch)
            prepareEpoch@SymphonyProtocol(obj, epoch);
            
            amplifierMode = obj.rigConfig.multiClampMode(obj.amp);
            epoch.addParameter('amplifierMode', amplifierMode);
            if ~isempty(obj.amp2)
                amplifier2Mode = obj.rigConfig.multiClampMode(obj.amp2);
                epoch.addParameter('amplifier2Mode', amplifier2Mode);
            end
            
        end
        
        function completeRun(obj)
           %save online analysis data
%             for i=1:length(obj.figureHandlers)
%                 if ismethod(obj.figureHandlers{i}, 'saveFigureData')
%                     %disp('found FigureHandler to save')                    
%                     if ~isempty(obj.persistor) %epochs being saved?
%                         cellID = obj.symphonyUI.epochGroup.userProperties.cellID;
%                         rigName = obj.symphonyUI.epochGroup.userProperties.rigName;
%                         year = obj.symphonyUI.epochGroup.startTime.Date.Year;
%                         month = obj.symphonyUI.epochGroup.startTime.Date.Month;
%                         day = obj.symphonyUI.epochGroup.startTime.Date.Day;
%                         outpath = [obj.symphonyUI.epochGroup.outputPath filesep 'analysisRecords'];
%                         curTimeStr = num2str(rem(now,1), 5);
%                         curTimeStr = strrep(curTimeStr, '.', 'p');
%                         fname = fullfile(outpath, [obj.displayName '_' obj.figureHandlers{i}.figureType '_' num2str(year) '_' num2str(month) '_' num2str(day) ...
%                             '-cell' cellID rigName '-' curTimeStr '-' obj.figureHandlers{i}.deviceName]); 
%                         obj.figureHandlers{i}.saveFigureData(fname);
%                     end
%                 end
%             end
%           

            completeRun@SymphonyProtocol(obj);
        end

    end
    
    methods
        
        % Convenience methods.
        
        function amp2 = get_amp2(obj)
            % The secondary amp is defined as the amp not selected as the main amp.            
            amps = obj.rigConfig.multiClampDeviceNames();
            
            if ~isempty(obj.amp)
                index = find(~ismember(amps, obj.amp), 1);
                if isempty(index)
                    amp2 = '';
                else
                    amp2 = amps{index};
                end
            else
                amp2 = '';
            end
        end
            
    end
    
end