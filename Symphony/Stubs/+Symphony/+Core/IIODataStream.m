classdef IIODataStream < handle
    
    properties (Abstract, SetAccess = private)
        SampleRate
        Duration
        Position
        IsAtEnd
    end
    
    methods
    end
    
end

