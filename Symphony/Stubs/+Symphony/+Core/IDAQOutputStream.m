classdef IDAQOutputStream < Symphony.Core.IDAQStream
   
    properties (Abstract)
        Device
    end
    
    properties (Abstract, SetAccess = private)
        HasMoreData
        Background        
    end
    
    methods (Abstract)
        outData = PullOutputData(obj, duration)
        Reset(obj)
        DidOutputData(obj, outputTime, duration, config)
    end
end