classdef TimeStampedDeviceDataEventArgs < Symphony.Core.TimeStampedEventArgs
    
    properties (SetAccess = private)
        Device
        Data
    end
    
    methods
        
        function obj = TimeStampedDeviceDataEventArgs(clock, device, data)
            obj = obj@Symphony.Core.TimeStampedEventArgs(clock);
            
            obj.Device = device;
            obj.Data = data;
        end
        
    end
    
end

