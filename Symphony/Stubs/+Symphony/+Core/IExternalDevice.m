classdef IExternalDevice < Symphony.Core.ITimelineProducer
   
    properties (Abstract)
        Controller
        Background
        Name
        Manufacturer
        InputSampleRate
        OutputSampleRate
    end
    
    properties (Abstract, SetAccess = private)
        Streams
        InputStreams
        OutputStreams
    end
    
    methods (Abstract)
        device = BindStream(obj, arg1, arg2);
        outData = PullOutputData(obj, stream, duration);
        PushInputData(obj, stream, inData);
        ApplyBackground(obj);
        DidOutputData(obj, stream, outputTime, timeSpan, config);
    end
end