% A substitute for an IEnumerable implementation.

classdef Enumerable < handle
    
    properties (Access = private)
        getEnumeratorFunc
    end
    
    methods
        
        function obj = Enumerable(getEnumeratorFunc)
            obj.getEnumeratorFunc = getEnumeratorFunc;
        end
        
        
        function e = GetEnumerator(obj)
            e = obj.getEnumeratorFunc();
        end
        
    end
    
end

