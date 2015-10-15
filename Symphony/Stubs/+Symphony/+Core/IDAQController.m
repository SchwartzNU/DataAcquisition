classdef IDAQController < Symphony.Core.ITimelineProducer & Symphony.Core.IHardwareController
    
    properties (Abstract, SetAccess = protected)
        ProcessInterval
    end
    
    properties (Abstract, SetAccess = private)
        Streams
        InputStreams
        OutputStreams
    end
    
    methods (Abstract)
        s = GetStream(obj, name);
    end
    
end