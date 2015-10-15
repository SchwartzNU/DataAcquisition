classdef Background < handle
    
    properties (SetAccess = private)
        Value
        SampleRate
    end
    
    methods
        
        function obj = Background(value, sampleRate)
            obj.Value = value;
            obj.SampleRate = sampleRate;
        end
        
    end
    
end

