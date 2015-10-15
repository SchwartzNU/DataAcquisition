classdef EventHandler < handle
    
    properties (SetAccess = private)
        Type
        Callback
    end
    
    methods
        
        function obj = EventHandler(type, callback)
            obj.Type = type;
            obj.Callback = callback;
        end
        
    end
    
end