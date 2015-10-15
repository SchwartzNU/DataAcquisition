% A wrapper around a core Epoch instance, making it easier and more efficient to work with in Matlab.

classdef EpochWrapper < handle
    
    properties
        waitForTrigger      % Indicates if the Epoch should wait for an external trigger before running.
        shouldBePersisted   % Indicates if the Epoch should be saved to the file after completion.
    end
    
    properties (Dependent, SetAccess = private)
        parameters          % A dictionary of parameters in the Epoch.
    end
    
    properties (Access = private)
        epoch
        deviceNameConverter
        responseCache
    end
    
    methods
        
        function obj = EpochWrapper(epoch, deviceNameConverter)
            obj.epoch = epoch;
            obj.deviceNameConverter = deviceNameConverter;
            obj.responseCache = containers.Map();
        end
        
        
        function addKeyword(obj, keyword)
            % Add a keyword to the Epoch.
            
            obj.epoch.Keywords.Add(keyword);
        end
        
        
        function addParameter(obj, name, value)
            % Add a parameter to the Epoch.
            
            if ~ischar(value) && length(value) > 1
                if isnumeric(value)
                    value = sprintf('%g ', value);
                else
                    error('Parameter values must be scalar or vectors of numbers.');
                end
            end
            
            obj.epoch.ProtocolParameters.Add(name, value);
        end
        
        
        function p = getParameter(obj, name)
            % Returns the value to a specified parameter in the Epoch.
            
            params = obj.epoch.ProtocolParameters;
            
            if ~params.ContainsKey(name)
                error(['Parameter ''' name ''' does not exist']);
            end
            
            p = obj.epoch.ProtocolParameters.Item(name);
        end
        
        
        function tf = containsParameter(obj, name)
            % Indicates if the Epoch contains a parameter with the given name.
        
            tf = obj.epoch.ProtocolParameters.ContainsKey(name);
        end
        
        
        function p = get.parameters(obj)
            % Returns all parameters in the Epoch.
            
            p = dictionaryToStruct(obj.epoch.ProtocolParameters);
        end
        
        
        function addStimulus(obj, deviceName, stimulus)
            % Add a stimulus to present when the Epoch is run. Duration is optional.
            
            import Symphony.Core.*;
            
            device = obj.deviceNameConverter(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            obj.epoch.Stimuli.Add(device, stimulus);
        end
        
        
        function setBackground(obj, deviceName, background, units)
            % Add a background to present in the absence of a stimulus when the Epoch is run.
            
            import Symphony.Core.*;
            
            device = obj.deviceNameConverter(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            background = Measurement(background, units);
            
            obj.epoch.SetBackground(device, background, device.OutputSampleRate);
        end
        
        
        function [b, u] = getBackground(obj, deviceName)
            % Returns the set background value and units for the device with the given name.
            
            device = obj.deviceNameConverter(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            if isempty(device.Background)
                error('%s has no set background.', deviceName);
            end
            
            b = double(System.Convert.ToDouble(device.Background.Quantity));
            u = char(device.Background.DisplayUnit);
        end
        
        
        function recordResponse(obj, deviceName)
            % Indicate that a response should be recorded from the device when the Epoch is run.
                   
            import Symphony.Core.*;
            
            device = obj.deviceNameConverter(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            obj.epoch.Responses.Add(device, Response());
        end
        
        
        function [r, s, u] = response(obj, deviceName)
            % Returns the recorded response, sample rate and units for the device with the given name.
            
            import Symphony.Core.*;
            
            if nargin == 1
                % If no device specified then pick the first one.
                devices = dictionaryKeysAndValues(obj.epoch.Responses);
                if isempty(devices)
                    error('No devices have had their responses recorded.');
                end
                device = devices{1};
            else
                device = obj.deviceNameConverter(deviceName);
                if isempty(device)
                    error('There is no device named ''%s''.', deviceName);
                end
            end
            
            deviceName = char(device.Name);
            
            if isKey(obj.responseCache, deviceName)
                % Use the cached response data.
                response = obj.responseCache(deviceName);
                r = response.data;
                s = response.sampleRate;
                u = response.units;
            else
                % Extract the raw data.
                try
                    response = obj.epoch.Responses.Item(device);
                    data = response.Data;
                    r = double(Measurement.ToQuantityArray(data));
                    u = char(Measurement.HomogenousDisplayUnits(data));
                catch ME %#ok<NASGU>
                    r = [];
                    u = '';
                end
                
                if ~isempty(r)
                    s = System.Decimal.ToDouble(response.SampleRate.QuantityInBaseUnit);
                    % TODO: do we care about the units of the SampleRate measurement?
                else
                    s = [];
                end
                
                % Cache the results.
                obj.responseCache(deviceName) = struct('data', r, 'sampleRate', s, 'units', u);
            end
        end
        
        
        function obj = set.waitForTrigger(obj, tf)
            obj.epoch.WaitForTrigger = tf;
        end
        
        
        function tf = get.waitForTrigger(obj)
            tf = obj.epoch.WaitForTrigger;
        end
        
        
        function obj = set.shouldBePersisted(obj, tf)
            obj.epoch.ShouldBePersisted = tf;
        end
            
        
        function tf = get.shouldBePersisted(obj)
            tf = obj.epoch.ShouldBePersisted;
        end
        
                
        function e = getCoreEpoch(obj)
            % Returns the core Epoch.
            
            e = obj.epoch;
        end
        
    end       
    
end