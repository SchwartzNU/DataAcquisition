classdef SystemClock < Symphony.Core.IClock
    
    properties (SetAccess = private)
        Now
    end
    
    methods
        
        function t = get.Now(obj)
            t = System.DateTimeOffset.Now;
        end
        
    end
    
end

