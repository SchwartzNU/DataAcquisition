classdef ArrayList < handle
   
    properties (SetAccess = private)
        Count
    end
    
    properties (Access = private)
        Capacity
        Items
        ItemCount
    end
    
    methods
        
        function obj = ArrayList(capacity)            
            if nargin == 0
                capacity = 10;
            end
            
            obj.Items = cell(1, capacity);
            obj.ItemCount = 0;
            obj.Capacity = capacity;
        end
        
        
        function Add(obj, item)
            obj.ItemCount = obj.ItemCount + 1;
            obj.Items{obj.ItemCount} = item;
        end
        
        
        function AddRange(obj, list)
            obj.Items = [obj.Items(1:obj.ItemCount) list.Items];
            obj.ItemCount = obj.ItemCount + list.ItemCount;
        end
        
        
        function Remove(obj, item)
            i = obj.IndexOf(item);
            
            obj.RemoveAt(i);
        end
        
        
        function RemoveAt(obj, index)
            obj.Items(index + 1) = [];
            obj.ItemCount = obj.ItemCount - 1;
        end
        
        
        function i = Item(obj, index, value)
            if index < 0 || index >= obj.ItemCount
                error('Out of range')
            end
            
            if nargin > 2
                obj.Items{index + 1} = value;
            end
            
            i = obj.Items{index + 1};   % index is zero based
        end
        
        
        function c = get.Count(obj)
            c = obj.ItemCount;
        end
        
        
        function Clear(obj)
            obj.Items = cell(1, obj.Capacity);
            obj.ItemCount = 0;
        end
        
        
        function i = IndexOf(obj, item)
            i = find(cellfun(@(c)isequal(c, item), obj.Items), 1, 'first');
            
            if isempty(i)
                i = -1;
            else
                i = i - 1; % index is zero based
            end
        end
        
        
        function b = Contains(obj, item)
            b = obj.IndexOf(item) ~= -1;
        end
        
        
        function enum = GetEnumerator(obj)
            enum = Enumerator(@MoveNext);
            enum.State = 0;
            
            function b = MoveNext()
                enum.Current = [];
                
                if enum.State + 1 > obj.ItemCount
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