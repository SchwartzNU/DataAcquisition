classdef Queue < handle
    
    properties (SetAccess = private)
        Count
    end
    
    properties (Access = private)
        Items
    end
    
    methods
        
        function obj = Queue()            
            obj.Items = cell(0);
            obj.Count = 0;
        end
        
        
        function Enqueue(obj, item)
            obj.Items{end + 1} = item;
            obj.Count = obj.Count + 1;
        end
        
        
        function i = Peek(obj)
            i = obj.Items{1};
        end
        
        
        function i = Dequeue(obj)
            i = obj.Items{1};
            obj.Items(1) = [];
            obj.Count = obj.Count - 1;
        end
        
        
        function Clear(obj)
            obj.Items = cell(0);
            obj.Count = 0;
        end
        
        
        function enum = GetEnumerator(obj)
            enum = Enumerator(@MoveNext);
            enum.State = 0;
            
            function b = MoveNext()
                enum.Current = [];
                
                if enum.State + 1 > obj.Count
                    b = false;
                    return;
                end
                
                enum.Current = obj.Items{enum.State + 1};
                enum.State = enum.State + 1;
                b = true;
            end
        end
        
    end
    
end

