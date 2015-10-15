classdef AggregateException < System.Exception
    
    methods
        
        function obj = AggregateException(message)            
            obj = obj@System.Exception(message);
        end
        
        
        function e = Flatten(obj)
            e = obj;
        end
        
    end
    
end

