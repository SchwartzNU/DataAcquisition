classdef IDAQStream < Symphony.Core.ITimelineProducer
   
    properties (Abstract)
        Configuration
        SampleRate
        MeasurementConversionTarget
    end
    
    properties (Abstract, SetAccess = private)
        Name
        CanSetSampleRate
        Active
        DAQ
    end

end