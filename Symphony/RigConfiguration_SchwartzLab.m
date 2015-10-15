classdef RigConfiguration_SchwartzLab < handle
    
    properties (Constant, Abstract)
        displayName
    end
    
    properties
        controller
    end
    
    properties (Dependent)
        sampleRate
    end
    
    properties (Hidden)
        symphonyUI                      % The main SymphonyUI instance.
        proxySampleRate                 % numeric, in Hz
    end
    
    methods
        
        function obj = init(obj, daqControllerFactory)
            % This method is essentially a constructor. If you need to override the constructor, override this instead.
            
            import Symphony.Core.*;
                        
            obj.controller = Controller();
            obj.controller.DAQController = daqControllerFactory.createDAQ();
            obj.controller.Clock = obj.controller.DAQController.Clock;
            
            obj.sampleRate = 10000;

            try
                obj.createDevices();
                
                % Have all devices start emitting their background values.
                obj.controller.DAQController.SetStreamsBackground();
            catch ME
                obj.close();
                throw(ME);
            end
        end
        
        
        function set.sampleRate(obj, rate)
            import Symphony.Core.*;             % import this so this method knows what a 'Measurement' - see below - is...

            if ~isnumeric(rate)
                error('Symphony:InvalidSampleRate', 'The sample rate for a rig configuration must be a number.');
            end
            
            % Update the rate of the DAQ controller.
            srProp = findprop(obj.controller.DAQController, 'SampleRate');
            if isempty(srProp)
                obj.proxySampleRate = rate;
            else
                obj.controller.DAQController.SampleRate = Measurement(rate, 'Hz');
            end
            
            % Update the rate of all output devices.
            outDevices = obj.outputDevices();
            for i = 1:length(outDevices)
                device = outDevices{i};
                
                device.OutputSampleRate = Measurement(rate, 'Hz');
                
                % Update device background stream rate.
                out = BackgroundOutputDataStream(Background(device.Background, device.OutputSampleRate));
                obj.controller.BackgroundDataStreams.Item(device, out);
            end
            
            % Update the rate of all input devices.
            inDevices = obj.inputDevices();
            for i = 1:length(inDevices)
                device = inDevices{i};
                
                device.InputSampleRate = Measurement(rate, 'Hz');
            end
            
            % Update the rate of all DAQ streams.
            enum = obj.controller.DAQController.Streams.GetEnumerator;
            while enum.MoveNext()
                stream = enum.Current;
                if stream.CanSetSampleRate
                    stream.SampleRate = Measurement(rate, 'Hz');
                end
            end
        end
        
        
        function rate = get.sampleRate(obj)
            srProp = findprop(obj.controller.DAQController, 'SampleRate');
            if isempty(srProp)
                rate = obj.proxySampleRate;
            else
                m = obj.controller.DAQController.SampleRate;
                if ~strcmp(char(m.BaseUnit), 'Hz')
                    error('Symphony:SampleRateNotInHz', 'The sample rate is not in Hz.');
                end
                rate = System.Decimal.ToDouble(m.QuantityInBaseUnit);
            end
        end
        
        
        function stream = streamWithName(obj, streamName, isOutput)
            import Symphony.Core.*;
            
            daq = obj.controller.DAQController;
            
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')     % TODO: or has method 'GetStream'?
                stream = daq.GetStream(streamName);
            else
                if isOutput
                    stream = DAQOutputStream(streamName, daq);
                else
                    stream = DAQInputStream(streamName, daq);
                end
                stream.SampleRate = Measurement(obj.sampleRate, 'Hz');
                stream.MeasurementConversionTarget = 'V';
                stream.Clock = daq.Clock;
                daq.AddStream(stream);
            end
        end
        
        
        function addStreams(obj, device, outStreamName, inStreamName)
            import Symphony.Core.*;
            
            % Create and bind any output stream.
            if ~isempty(outStreamName)
                stream = obj.streamWithName(outStreamName, true);
                device.BindStream(stream);
                device.OutputSampleRate = Measurement(obj.sampleRate, 'Hz');
            end
            
            % Create and bind any input stream.
            if ~isempty(inStreamName)
                stream = obj.streamWithName(inStreamName, false);
                device.BindStream(stream);
                device.InputSampleRate = Measurement(obj.sampleRate, 'Hz');
            end
        end
        
        
        function addDevice(obj, deviceName, outStreamName, inStreamName)            
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            
            if strncmp(outStreamName, 'DIGITAL', 7) || strncmp(inStreamName, 'DIGITAL', 7)
                units = Measurement.UNITLESS;                   
            else
                units = 'V';
            end
            
            dev = UnitConvertingExternalDevice(deviceName, 'unknown', obj.controller, Measurement(0, units));
            dev.MeasurementConversionTarget = units;
            dev.Clock = obj.controller.DAQController.Clock;
            
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')
                if strncmp(outStreamName, 'DIGITAL_OUT.', 12)
                    % Heka digital outputs are individual bits of digital output stream 1.
                    bitPosition = str2double(regexprep(outStreamName, '^[^.]*.', ''));
                    outStreamName = 'DIGITAL_OUT.1';
                    
                    stream = obj.streamWithName(outStreamName, true);
                    stream.BitPositions.Add(dev, bitPosition);
                end
                
                if strncmp(inStreamName, 'DIGITAL_IN.', 11)
                    % Heka digital inputs are individual bits of digital input stream 0.
                    bitPosition = str2double(regexprep(inStreamName, '^[^.]*.', ''));
                    inStreamName = 'DIGITAL_IN.0';
                    
                    stream = obj.streamWithName(inStreamName, false);
                    stream.BitPositions.Add(dev, bitPosition);
                end
            end
            
            obj.addStreams(dev, outStreamName, inStreamName);
            
            % Set default device background stream in the controller.
            if ~isempty(outStreamName)
                out = BackgroundOutputDataStream(Background(Measurement(0, units), dev.OutputSampleRate));
                obj.controller.BackgroundDataStreams.Item(dev, out);
            end
        end
        
        
        function mode = multiClampMode(obj, deviceName)
            if nargin == 2 && ~isempty(deviceName)
                device = obj.deviceWithName(deviceName);
            else
                % Find a MultiClamp device to query.
                devices = obj.multiClampDevices();
                if ~isempty(devices)
                    device = devices{1};
                end
            end

            if isempty(device)
                error('Symphony:MultiClamp:NoDevice', 'Cannot determine the MultiClamp mode because no MultiClamp device has been created.');
            end

            outStreams = enumerableToCellArray(device.OutputStreams, 'Symphony.Core.IDAQOutputStream');
            requireOutMode = ~isempty(outStreams);
            
            inStreams = enumerableToCellArray(device.InputStreams, 'Symphony.Core.IDAQInputStream');
            requireInMode = ~isempty(inStreams);
            
            % Try to get the multiclamp mode from the commander.
            start = tic;
            timeOutSeconds = 2;
            mode = '';
            while isempty(mode)              
                                
                outMode = '';
                if requireOutMode && device.HasDeviceOutputParameters
                    outMode = char(device.CurrentDeviceOutputParameters.Data.OperatingMode);
                end
                                
                inMode = '';
                if requireInMode && device.HasDeviceInputParameters
                    inMode = char(device.CurrentDeviceInputParameters.Data.OperatingMode);
                end
                
                if requireOutMode && requireInMode
                    if strcmp(outMode, inMode)
                        mode = outMode;
                    end
                elseif requireOutMode
                    mode = outMode;
                else
                    mode = inMode;
                end
                
                if isempty(mode)
                    if toc(start) < timeOutSeconds
                        pause(0.25);
                    else
                        input(['Please toggle the MultiClamp commander for ' deviceName ' mode then press enter (or Ctrl-C to cancel)...'], 's'); 
                    end
                end
            end
        end
        
        
        function addMultiClampDevice(obj, deviceName, channel, outStreamName, inStreamName)
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            
            if channel ~= 1 && channel ~= 2
                error('Symphony:MultiClamp:InvalidChannel', 'The MultiClamp channel must be either 1 or 2.');
            end
            
            % TODO: validate that the same channel is not added a second time?
            
            % Get the local serial number of the MultiClamp.
            % (Stored as a local pref so that each rig can have its own value.)
            if ispref('Symphony', 'MultiClamp_SerialNumber')
                multiClampSN = getpref('Symphony', 'MultiClamp_SerialNumber', '');
            else
                multiClampSN = getpref('MultiClamp', 'SerialNumber', '');
                if ispref('MultiClamp') && ~isempty(multiClampSN)
                    setpref('Symphony', 'MultiClamp_SerialNumber', multiClampSN);
                    rmpref('MultiClamp');
                end
            end
            if isempty(multiClampSN)
                answer = inputdlg({'Enter the serial number of the MultiClamp:'}, 'Symphony', 1, {'831400'});
                if isempty(answer)
                    error('Symphony:MultiClamp:NoSerialNumber', 'Cannot create a MultiClamp device without a serial number');
                else
                    multiClampSN = uint32(str2double(answer{1}));
                    setpref('Symphony', 'MultiClamp_SerialNumber', multiClampSN);
                end
            end
            
            % Create the device so we can query for the current mode.
            modes = NET.createArray('System.String', 3);
            modes(1) = 'VClamp';
            modes(2) = 'I0';
            modes(3) = 'IClamp';
            
            backgroundMeasurements = NET.createArray('Symphony.Core.IMeasurement', 3);
            backgroundMeasurements(1) = Measurement(0, 'V');
            backgroundMeasurements(2) = Measurement(0, 'A');
            backgroundMeasurements(3) = Measurement(0, 'A');
            
            dev = MultiClampDevice(multiClampSN, channel, obj.controller.DAQController.Clock, obj.controller,...
                modes,...
                backgroundMeasurements...
                );
            dev.Name = deviceName;
            dev.Clock = obj.controller.DAQController.Clock;
            
            % Bind the streams.
            obj.addStreams(dev, outStreamName, inStreamName);
            
            % Make sure the current mode of the MultiClamp is known.
            try
                obj.multiClampMode(deviceName);
            catch ME
                dev.Controller = [];
                if iscell(obj.controller.Devices)
                    for i = 1:length(obj.controller.Devices)
                        if obj.controller.Devices{i} == dev
                            obj.controller.Devices(i) = [];
                            break;
                        end
                    end
                else
                    obj.controller.Devices.Remove(dev);
                end
                throw(ME);
            end
        end
        
        function addStageDevice(obj, deviceName)
         %do nothing for now
        end
                
        function d = devices(obj)
            d = listValues(obj.controller.Devices);
        end
        
        
        function d = outputDevices(obj)
            d = {};
            
            devices = obj.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                outStreams = enumerableToCellArray(device.OutputStreams, 'Symphony.Core.IDAQOutputStream');
                if ~isempty(outStreams)
                    d{end + 1} = device;
                end
            end
        end
        
        
        function d = inputDevices(obj)
            d = {};
            
            devices = obj.devices();
            for i = 1:length(devices)
                device = devices{i};
                
                inStreams = enumerableToCellArray(device.InputStreams, 'Symphony.Core.IDAQInputStream');
                if ~isempty(inStreams)
                    d{end + 1} = device;
                end
            end
        end
        
        
        function d = multiClampDevices(obj)
            d = {};
            devices = obj.devices();
            for i = 1:length(devices)
                if isa(devices{i}, 'Symphony.ExternalDevices.MultiClampDevice')
                    d{end + 1} = devices{i};
                end
            end
        end
        
        
        function n = numMultiClampDevices(obj)
            n = length(obj.multiClampDevices());
        end
                
        
        function names = deviceNames(obj, expr)
            % Returns all device names with a match of the given regular expression.
            
            if nargin < 2
                expr = '.';
            end
            
            names = {};
            devices = obj.devices();
            for i = 1:length(devices)
                name = char(devices{i}.Name);
                if ~isempty(regexpi(name, expr, 'once'))
                    names{end + 1} = name;
                end
            end            
        end
        
        
        function names = multiClampDeviceNames(obj)            
            names = {};
            devices = obj.multiClampDevices();
            for i = 1:length(devices)
                names{end + 1} = char(devices{i}.Name);
            end
        end
        
        
        function device = deviceWithName(obj, name)
            device = obj.controller.GetDevice(name);
        end
        
        
        function desc = describeDevices(obj)
            desc = '';
            devices = obj.devices();
            for i = 1:length(devices)
                [~, streams] = dictionaryKeysAndValues(devices{i}.Streams);
                for j = 1:length(streams)
                    if isa(streams{j}, 'Symphony.Core.IDAQInputStream')
                        if isa(streams{j}, 'Heka.HekaDigitalDAQStream')
                            bit = streams{j}.BitPositions.Item(devices{i});
                            desc = [desc sprintf('%s  <--  %s\n', char(devices{i}.Name), ['DIGITAL_IN.' num2str(bit)])];
                        else
                            desc = [desc sprintf('%s  <--  %s\n', char(devices{i}.Name), char(streams{j}.Name))];
                        end
                    else
                        if isa(streams{j}, 'Heka.HekaDigitalDAQStream')
                            bit = streams{j}.BitPositions.Item(devices{i});
                            desc = [desc sprintf('%s  -->  %s\n', char(devices{i}.Name), ['DIGITAL_OUT.' num2str(bit)])];
                        else
                            desc = [desc sprintf('%s  -->  %s\n', char(devices{i}.Name), char(streams{j}.Name))];
                        end
                    end
                end
            end
        end
        
        
        function prepared(obj)
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')
                obj.controller.DAQController.SetStreamsBackground();
            end
        end
        
        
        function close(obj)
            % Release any hold we have on hardware.
            
            % Force dispose any multiclamp devices to ensure commander listeners are removed.
            devices = obj.multiClampDevices();
            for i = 1:length(devices)
                devices{i}.Dispose();
            end
            
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')
                obj.controller.DAQController.CloseHardware();
            end
        end
        
    end
    
    
    methods (Abstract)
        
        createDevices(obj);
        
    end
    
end


%% To support units coversion:
%
% fromUnits = 'foo'
% toUnits = 'V'
% Converters.Register(fromUnits, toUnits, @conversionProc);
% 
% 
% function measurementOut = conversionProc(measurementIn)
%   ...
% end
