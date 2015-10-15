classdef KeyValuePair
    
    properties (SetAccess = private)
        Key
        Value
    end
    
    methods
        
        function obj = KeyValuePair(key, value)
            obj.Key = key;
            obj.Value = value;
        end
        
    end
    
end

