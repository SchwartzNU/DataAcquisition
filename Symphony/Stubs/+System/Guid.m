classdef Guid
   
    properties (Access = private)
        Id
    end
    
    methods (Static)
        
        function guid = NewGuid()
            id = java.util.UUID.randomUUID();
            guid = System.Guid(id);
        end
        
    end
    
    methods
        
        function obj = Guid(id)
            obj.Id = id;
        end
        
        
        function s = ToString(obj)
            s = char(obj.Id);
        end
        
    end
end