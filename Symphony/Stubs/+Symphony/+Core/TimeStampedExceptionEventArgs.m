classdef TimeStampedExceptionEventArgs < Symphony.Core.TimeStampedEventArgs
    
    properties (SetAccess = private)
        Exception
    end
    
    methods
        
        function obj = TimeStampedExceptionEventArgs(clock, exception)
            obj@Symphony.Core.TimeStampedEventArgs(clock);
            obj.Exception = exception;
        end
        
    end
    
end

