classdef IOutputDataStream < Symphony.Core.IIODataStream
    
    properties (Abstract, SetAccess = private)
        OutputPosition
        IsOutputAtEnd
    end
    
    methods (Abstract)
        outData = PullOutputData(obj, duration);
        DidOutputData(obj, outputTime, timeSpan, config);
    end
    
end

