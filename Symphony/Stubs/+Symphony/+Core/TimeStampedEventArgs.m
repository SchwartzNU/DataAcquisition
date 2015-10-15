classdef TimeStampedEventArgs < event.EventData
    
    properties (SetAccess = private)
        TimeStamp
    end
    
    methods
        
        function obj = TimeStampedEventArgs(clock)
            obj.TimeStamp = clock.Now;
        end
        
    end
    
end

