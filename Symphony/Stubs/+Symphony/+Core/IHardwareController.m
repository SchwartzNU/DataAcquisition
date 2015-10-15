classdef IHardwareController < handle
    
    properties (Abstract, SetAccess = protected)
        Running
    end
    
    methods (Abstract)
        Start(obj, waitForTrigger)
        Stop(obj);
    end
    
end