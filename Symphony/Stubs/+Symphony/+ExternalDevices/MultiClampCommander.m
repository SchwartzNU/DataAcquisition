classdef MultiClampCommander < handle
   
    properties
        Clock
    end
    
    properties (SetAccess = private)
        SerialNumber
        Channel
    end    
    
    methods
        
        function obj = MultiClampCommander(serialNumber, channel, clock)
            obj.SerialNumber = serialNumber;
            obj.Channel = channel;
            obj.Clock = clock;
        end
        
    end
end