classdef Enumerable < handle
    
    methods (Static)
        
        function list = ToList(source)
            % This doesn't need to do anything at the moment. It just needs to exist.
            list = source;
        end
        
        
        function first = First(source)
            e = source.GetEnumerator();
            
            if ~e.MoveNext()
                error('Empty enumerable');
            end
            
            first = e.Current;
        end
        
    end
    
end

