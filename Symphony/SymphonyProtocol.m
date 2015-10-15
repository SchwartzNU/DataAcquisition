% Create a sub-class of this class to define a protocol.
%
% Interesting methods to override:
% * prepareRun
% * prepareEpoch
% * completeEpoch
% * continueQueuing
% * continueRun
% * completeRun

classdef SymphonyProtocol < handle & matlab.mixin.Copyable
    
    properties (Constant, Abstract)
        identifier                              % Use reverse domain name notation.
        version
        displayName
    end
    
    properties (Hidden)
        symphonyUI                              % The main SymphonyUI instance.
        state                                   % The state the protocol is in: 'stopped', 'running', 'paused', etc.
        rigConfig                               % A RigConfiguration instance.
        rigPrepared = false                     % A flag indicating whether the rig is ready to run this protocol.
        figureHandlerClasses = containers.Map
        figureHandlers = {}
        figureHandlerParams = {}
        allowSavingEpochs = true                % An indication if this protocol allows it's data to be persisted.
        allowPausing = true                     % An indication if this protocol allows pausing during acquisition.
        persistor = []                          % The persistor to use with each epoch.
        epochKeywords = {}                      % A cell array of string containing keywords to be applied to any upcoming epochs.
        epochQueueSize = 6                      % The maximum number of epochs/intervals this protocol will queue into the epoch queue at one time.
        numEpochsQueued                         % The number of epochs queued by this protocol in the current run.
        numEpochsCompleted                      % The number of epochs completed by this protocol in the current run.
        numIntervalsQueued                      % The number of intervals queued by this protocol in the current run.
        numIntervalsCompleted                   % The number of intervals completed by this protocol in the current run.
    end
    
    properties        
        sampleRate = {10000, 20000, 50000, 1000}      % in Hz
    end
    
    events
        StateChanged
    end
    
    methods
        
        function obj = init(obj, rigConfig)
            % This method is essentially a constructor. If you need to override the constructor, override this instead.
            
            obj.setState('stopped');
            obj.rigConfig = rigConfig;
        end
        
        
        function setState(obj, state)
            obj.state = state;
            notify(obj, 'StateChanged');
        end
        
        
        function dn = requiredDeviceNames(obj) %#ok<MANU>
            % Override this method to indicate the names of devices that are required for this protocol.
            dn = {};
        end
        
        
        function [tf , msg] = isCompatibleWithRigConfig(obj, rigConfig)
            % Returns true/false and a message to indicate if a given rig configuration is compatible with this protocol.
            
            tf = true;
            msg = '';
            
            deviceNames = obj.requiredDeviceNames();
            for i = 1:length(deviceNames)
                device = rigConfig.deviceWithName(deviceNames{i});
                if isempty(device)
                    tf = false;
                    msg = ['This protocol cannot be run because there is no ''' deviceNames{i} ''' device.'];
                    break;
                end                
            end
        end
        
        
        function prepareRig(obj)
            % Override this method to perform any actions to get the rig ready for running the protocol, e.g. setting device backgrounds, etc.
            
            obj.rigConfig.sampleRate = obj.sampleRate;
        end
        
        
        function prepareRun(obj)
            % Override this method to perform any actions before the start of the first epoch, e.g. open a figure window, set device backgrounds, etc.
                   
            import Symphony.Core.*;
            
            obj.numEpochsQueued = 0;
            obj.numEpochsCompleted = 0;
            
            obj.numIntervalsQueued = 0;
            obj.numIntervalsCompleted = 0;
            
            obj.clearFigures();
            
            % Clear out any epochs in the epoch queue.
            obj.rigConfig.controller.ClearEpochQueue();
            
            % Set the background streams for multiclamp devices to match their current mode background.
            amps = obj.rigConfig.multiClampDevices();
            for i = 1:length(amps)
                amp = amps{i};
                
                outStreams = enumerableToCellArray(amp.OutputStreams, 'Symphony.Core.IDAQOutputStream');
                if ~isempty(outStreams)
                    currentModeBackground = Background(amp.Background, amp.OutputSampleRate);
                    obj.rigConfig.controller.BackgroundDataStreams.Item(amp, BackgroundOutputDataStream(currentModeBackground));
                end
            end 
        end
        
        
        function pn = parameterNames(obj, includeConstant)
            % Return a cell array of strings containing the names of the user-defined parameters.
            % By default any parameters defined by a protocol that are not constant or hidden are included.
            
            if nargin == 1
                includeConstant = false;
            end
            
            names = properties(obj);
            pn = {};
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                metaProp = findprop(obj, name);
                if ~metaProp.Hidden && (includeConstant || ~metaProp.Constant)
                    pn{end + 1} = name; %#ok<AGROW>
                end
            end
            pn = pn';
        end
        
        
        function p = parameterProperty(obj, parameterName)
            % Return a ParameterProperty object for the specified parameter.
            
            metaProp = findprop(obj, parameterName);
            p = ParameterProperty(metaProp);
            switch parameterName
                case 'sampleRate'
                    p.units = 'Hz';
            end
        end
        
        
        function p = parameters(obj, includeConstant)
            % Return a struct containing the user-defined parameters.
            % By default any parameters defined by a protocol are included.
            
            if nargin == 1
                includeConstant = false;
            end
            
            names = obj.parameterNames(includeConstant);
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                p.(name) = obj.(name);
            end
        end
        
        
        function stimuli = sampleStimuli(obj) %#ok<MANU>
            stimuli = {};
        end
        
        
        function prepareEpoch(obj, epoch)
            % Override this method to add stimuli, record responses, change parameters, etc.
            
            import Symphony.Core.*;
            
            % Add any keywords specified by the user.
            for i = 1:length(obj.epochKeywords)
                epoch.addKeyword(obj.epochKeywords{i});
            end
            
            % Set default epoch backgrounds.
            outDevices = obj.rigConfig.outputDevices();
            for i = 1:length(outDevices)
                device = outDevices{i};
                epoch.setBackground(char(device.Name), device.Background.Quantity, device.Background.DisplayUnit);
            end
            
            % Record default responses.
            inDevices = obj.rigConfig.inputDevices();
            for i = 1:length(inDevices)
                device = inDevices{i};
                epoch.recordResponse(char(device.Name));
            end
        end
        
        
        function p = epochSpecificParameters(obj, epoch)
            % Determine the parameters unique to the epoch.
            % TODO: diff against the previous epoch's parameters instead?
            protocolParams = obj.parameters();
            p = structDiff(epoch.parameters, protocolParams);
        end
        
        
        function setDeviceBackground(obj, deviceName, background, units)
            % Set a constant background value for a device in the absence of an epoch.            
            
            import Symphony.Core.*;
            
            device = obj.rigConfig.deviceWithName(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            background = Measurement(background, units);
            
            % Set device background.
            if isa(device, 'Symphony.ExternalDevices.MultiClampDevice')
                % Set the background for the appropriate mode and for the device if the current mode matches.
                if strcmp(char(background.BaseUnit), 'V')
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.VClamp, background);
                else
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.IClamp, background);
                    device.SetBackgroundForMode(Symphony.ExternalDevices.OperatingMode.I0, background);
                end
            else
                device.Background = background;
            end
            
            % Set controller background stream for device.
            outStreams = enumerableToCellArray(device.OutputStreams, 'Symphony.Core.IDAQOutputStream');
            if ~isempty(outStreams)
                out = BackgroundOutputDataStream(Background(background, device.OutputSampleRate));
                obj.rigConfig.controller.BackgroundDataStreams.Item(device, out);
            end
            
            % Apply the background immediately.
            device.ApplyBackground();
        end
        
        
        function queueInterval(obj, durationInSeconds)
            % Queues an interval of given duration.
            
            import Symphony.Core.*;
            
            if durationInSeconds <= 0
                error('An interval must be greater than zero seconds');
            end
            
            % Create an interval epoch.
            intervalEpoch = EpochWrapper(Epoch(obj.identifier), @(name)obj.rigConfig.deviceWithName(name));
            intervalEpoch.addParameter('isIntervalEpoch', true);
            
            intervalEpoch.shouldBePersisted = false;
            
            outDevices = obj.rigConfig.outputDevices();
            if isempty(outDevices)
                error('There must be at least one output device to add an interval.');
            end
            
            % Set the interval epoch background values to the device background for all output devices.
            for i = 1:length(outDevices)
                device = outDevices{i};
                intervalEpoch.setBackground(char(device.Name), device.Background.Quantity, device.Background.DisplayUnit);
            end
            
            % Add a stimulus of background to give the epoch duration.
            deviceName = char(outDevices{1}.Name);
            [background, units] = intervalEpoch.getBackground(deviceName);
            
            p = PulseGenerator();
            p.preTime = 0;
            p.stimTime = durationInSeconds * 1e3;
            p.tailTime = 0;
            p.amplitude = 0;
            p.mean = background;
            p.sampleRate = obj.sampleRate;
            p.units = units;
            
            intervalEpoch.addStimulus(deviceName, p.generate());
            
            % Queue the interval epoch.
            obj.rigConfig.controller.EnqueueEpoch(intervalEpoch.getCoreEpoch);
            
            obj.numIntervalsQueued = obj.numIntervalsQueued + 1;
        end
        
        
        function completeEpoch(obj, epoch)
            % Override this method to perform any post-analysis, etc. on a completed epoch.
            
            obj.numEpochsCompleted = obj.numEpochsCompleted + 1;
            
            obj.updateFigures(epoch);
        end
        
        
        function completeInterval(obj, intervalEpoch) %#ok<INUSD>
            % Override this method to perform any actions on a completed interval.
            
            obj.numIntervalsCompleted = obj.numIntervalsCompleted + 1;
        end
        
        
        function keepQueuing = continueQueuing(obj)
            % Override this method to return true/false to indicate if the protocol should continue queuing epochs.
            % numEpochsQueued is typically useful.
            
            keepQueuing = strcmp(obj.state, 'running');
        end
        
        
        function keepGoing = continueRun(obj)
            % Override this method to return true/false to indicate if the protocol should continue running.
            % numEpochsCompleted is typically useful.
            
            keepGoing = strcmp(obj.state, 'running');
        end
        
        
        function completeRun(obj)
            % Override this method to perform any actions after the last epoch has completed.
            
            obj.setState('stopped');
        end
        
        
        function run(obj)
            % This is the core method that runs a protocol, everything else is preparation for this.
            
            if ~strcmp(obj.state, 'paused')
                % Prepare the run.
                obj.prepareRun();
            end
            
            obj.setState('running');
            
            % Add an event listener for completed epochs.
            epochCompleted = addNetListener(obj.rigConfig.controller, 'CompletedEpoch', 'Symphony.Core.TimeStampedEpochEventArgs', @completedEpoch);
            
            function completedEpoch(src, data) %#ok<INUSL>
                try
                    % Wrap the completed epoch.
                    epoch = EpochWrapper(data.Epoch, @(name)obj.rigConfig.deviceWithName(name));
                    if epoch.containsParameter('isIntervalEpoch')
                        obj.completeInterval(epoch);
                    else
                        obj.completeEpoch(epoch);
                    end
                    % Stop if this is the last epoch the protocol needed to complete.
                    if strcmp(obj.state, 'running') && ~obj.continueRun()
                        obj.stop();
                    end
                catch err
                    % A workaround for Matlab's missing exception stack in callback functions.
                    warning(getReport(err));
                end
            end
            
            % Add an event listener for discarded epochs.
            epochDiscarded = addNetListener(obj.rigConfig.controller, 'DiscardedEpoch', 'Symphony.Core.TimeStampedEpochEventArgs', @discardedEpoch);
            
            function discardedEpoch(src, data) %#ok<INUSD>
                try
                    obj.stop();
                catch err
                    % A workaround for Matlab's missing exception stack in callback functions.
                    warning(getReport(err));
                end
            end
            
            try 
                if obj.continueRun()
                    % Preload a buffer of epochs into the epoch queue.
                    obj.preloadQueue();
                    
                    % Process the protocol.
                    obj.process();
                end
            catch e
                obj.stop();
                waitfor(errordlg(['An error occurred while running the protocol.' char(10) char(10) getReport(e, 'extended', 'hyperlinks', 'off')]));
            end
            
            % Flush event queue and remove the event listeners.
            drawnow;
            removeNetListener(obj.rigConfig.controller, 'CompletedEpoch', epochCompleted);
            removeNetListener(obj.rigConfig.controller, 'DiscardedEpoch', epochDiscarded);
            
            if strcmp(obj.state, 'pausing')
                obj.setState('paused');
            else
                % Perform any final analysis, clean up, etc.
                obj.completeRun();
            end
        end
        
        
        function preloadQueue(obj)
            % This is the core method that preloads the epoch queue with a buffer of epochs before starting. Called by run().
            
            import Symphony.Core.*;
            
            % Queue epochs to fill the epoch queue.
            while obj.numEpochsQueued - obj.numEpochsCompleted + obj.numIntervalsQueued - obj.numIntervalsCompleted < obj.epochQueueSize && obj.continueQueuing()
                
                % Create a new wrapped core epoch.
                epoch = EpochWrapper(Epoch(obj.identifier), @(name)obj.rigConfig.deviceWithName(name));
                
                % Prepare the epoch: set backgrounds, add stimuli, record responses, add parameters, etc.
                obj.prepareEpoch(epoch);
                
                % Persist the params now that the sub-class has had a chance to tweak them.
                pluginParams = obj.parameters(true);
                fields = fieldnames(pluginParams);
                for fieldName = fields'
                    fieldValue = pluginParams.(fieldName{1});
                    if ~ischar(fieldValue) && length(fieldValue) > 1
                        if isnumeric(fieldValue)
                            fieldValue = sprintf('%g ', fieldValue);
                        else
                            error('Parameter values must be scalar or vectors of numbers.');
                        end
                    end
                    epoch.addParameter(fieldName{1}, fieldValue);
                end
                
                % Queue the prepared epoch.
                obj.queueEpoch(epoch);
            end
        end
        
        
        function process(obj)
            % This is the core method that processes the protocol. Called by run().
            
            import Symphony.Core.*;
            
            controller = obj.rigConfig.controller;
            
            % Start processing the epoch queue in the background.
            processTask = controller.StartAsync(obj.persistor);
            
            obj.waitToContinueQueuing();
                        
            % Queue until the protocol tells us to stop.
            while obj.continueQueuing()
                
                % Create a new wrapped core epoch.
                epoch = EpochWrapper(Epoch(obj.identifier), @(name)obj.rigConfig.deviceWithName(name));
                
                % Prepare the epoch: set backgrounds, add stimuli, record responses, add parameters, etc.
                obj.prepareEpoch(epoch);
                
                % Persist the params now that the sub-class has had a chance to tweak them.
                pluginParams = obj.parameters(true);
                fields = fieldnames(pluginParams);
                for fieldName = fields'
                    fieldValue = pluginParams.(fieldName{1});
                    if ~ischar(fieldValue) && length(fieldValue) > 1
                        if isnumeric(fieldValue)
                            fieldValue = sprintf('%g ', fieldValue);
                        else
                            error('Parameter values must be scalar or vectors of numbers.');
                        end
                    end
                    epoch.addParameter(fieldName{1}, fieldValue);
                end
                
                % Queue the prepared epoch.
                obj.queueEpoch(epoch);
                
                if ~isa(controller, 'System.Object')
                    % The stub controller must run after each queued epoch.
                    processTask = controller.StartAsync(obj.persistor);
                end
                
                obj.waitToContinueQueuing();
            end
            
            % Spin until the controller stops.
            while controller.IsRunning
                pause(0.01);
            end
            
            if processTask.IsFaulted
                error(netReport(NET.NetException('', '', processTask.Exception.Flatten())));
            end
        end
        
        
        function queueEpoch(obj, epoch)
            % This is the core method that enqueues an epoch into the epoch queue. Called by process().
            
            obj.rigConfig.controller.EnqueueEpoch(epoch.getCoreEpoch);
            
            obj.numEpochsQueued = obj.numEpochsQueued + 1;
        end
        
        
        function waitToContinueQueuing(obj)
            % This is the core method that blocks queuing another epoch until a condition has been reached. Called by process().
            
            % Wait only when there is a full buffer of epochs in the epoch queue.
            while obj.numEpochsQueued - obj.numEpochsCompleted + obj.numIntervalsQueued - obj.numIntervalsCompleted >= obj.epochQueueSize && strcmp(obj.state, 'running')
                pause(0.01);
            end
        end
        
        
        function pause(obj)
            % Set a flag that will be checked after the current epoch completes.
            obj.setState('pausing');
            
            % Request that the controller pause the epoch queue after completing any incomplete epochs.
            obj.rigConfig.controller.RequestPause();
        end
        
        
        function stop(obj)            
            if strcmp(obj.state, 'paused')
                obj.completeRun()
            else                
                % Set a flag that will be checked after the controller stops the current run.
                obj.setState('stopping');
                
                % Request that the controller stop the epoch queue and discard any incomplete epochs.
                obj.rigConfig.controller.RequestStop();
            end
        end
        
    end
    
    
    methods
        
        % Figure handling methods.
        
        function handler = openFigure(obj, figureType, varargin)
            if ~isKey(obj.figureHandlerClasses, figureType)
                error('The ''%s'' figure handler is not available.', figureType);
            end
            
            handlerClass = obj.figureHandlerClasses(figureType);
            
            % Check if the figure is open already.
            for i = 1:length(obj.figureHandlers)
                if strcmp(class(obj.figureHandlers{i}), handlerClass) && isequal(obj.figureHandlerParams{i}, varargin)
                    handler = obj.figureHandlers{i};
                    handler.showFigure();
                    return;
                end
            end
            
            % Create a new handler.
            constructor = str2func(handlerClass);
            handler = constructor(obj, varargin{:});
            addlistener(handler, 'FigureClosed', @(source, event)figureClosed(obj, source, event));
            obj.figureHandlers{end + 1} = handler;
            obj.figureHandlerParams{end + 1} = varargin;
        end
        
        
        function updateFigures(obj, epoch)
            for index = 1:numel(obj.figureHandlers)
                figureHandler = obj.figureHandlers{index};
                figureHandler.handleEpoch(epoch);
            end
        end
        
        
        function clearFigures(obj)
            for index = 1:numel(obj.figureHandlers)
                figureHandler = obj.figureHandlers{index};
                figureHandler.clearFigure();
            end
        end
        
        
        function closeFigures(obj)
            % Close any figures that were opened.
            while ~isempty(obj.figureHandlers)
                obj.figureHandlers{1}.close();
            end
        end
        
        
        function figureClosed(obj, handler, ~)
            % Remove the handler from our list.
            index = cellfun(@(x) x == handler, obj.figureHandlers);
            obj.figureHandlers(index) = [];
            obj.figureHandlerParams(index) = [];
        end
        
    end
    
end
