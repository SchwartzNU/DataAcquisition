classdef TimeStampedEpochEventArgs < Symphony.Core.TimeStampedEventArgs
    
    properties (SetAccess = private)
        Epoch
    end
    
    methods
        
        function obj = TimeStampedEpochEventArgs(clock, epoch)
            obj = obj@Symphony.Core.TimeStampedEventArgs(clock);
            
            obj.Epoch = epoch;
        end
        
    end
    
end

