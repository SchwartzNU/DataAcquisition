classdef IInputDataStream < Symphony.Core.IIODataStream
    
    properties
    end
    
    methods (Abstract)
        PushInputData(obj, inData);
    end
    
end