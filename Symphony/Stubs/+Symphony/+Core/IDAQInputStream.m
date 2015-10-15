classdef IDAQInputStream < Symphony.Core.IDAQStream
   
    properties (Abstract, SetAccess = private)
        Devices
    end
    
    methods (Abstract)
        PushInputData(obj, inData);
    end
    
end