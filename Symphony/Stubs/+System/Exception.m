classdef Exception < handle
    
    properties
        InnerException
        Message
    end
    
    methods
        
        function obj = Exception(message)           
            obj.Message = message;
        end
        
    end
    
end

