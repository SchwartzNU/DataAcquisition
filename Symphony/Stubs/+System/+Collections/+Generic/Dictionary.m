% Note that this implementation doesn't actually type check for simplicity's sake.

classdef Dictionary < handle
   
    properties (SetAccess = private)
        Types
        Keys
        Values
        Count
    end
    
    methods
        
        function obj = Dictionary(types)
            obj.Types = types;            
            obj.Keys = System.Collections.ArrayList();
            obj.Values = System.Collections.ArrayList();
        end
        
        
        function Add(obj, key, value)
            if obj.Keys.Contains(key)
                error('Key already exists');
            end
            
            obj.Keys.Add(key);
            obj.Values.Add(value);
        end
        
        
        function tf = Remove(obj, key)
            if ~obj.Keys.Contains(key)
                tf = false;
                return;
            end
            
            i = obj.Keys.IndexOf(key);
            obj.Keys.RemoveAt(i);
            obj.Values.RemoveAt(i);
        end
        
        
        function i = Item(obj, key, value)
            index = obj.Keys.IndexOf(key);
                       
            if nargin <= 2
                if index == -1
                    error('Key does not exist');
                else
                    i = obj.Values.Item(index);
                end
            else
                if index == -1
                    obj.Keys.Add(key);
                    obj.Values.Add(value);
                    i = value;
                else
                    i = obj.Values.Item(index, value);
                end
            end
        end
        
        
        function c = ContainsKey(obj, key)
            c = obj.Keys.Contains(key);
        end
        
        
        function c = get.Count(obj)
            c = obj.Keys.Count;
        end

        
        function Clear(obj)
            obj.Keys.Clear();
            obj.Values.Clear();
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
                
                key = obj.Keys.Item(enum.State);
                value = obj.Values.Item(enum.State);
                enum.Current = System.Collections.Generic.KeyValuePair(key, value);
                enum.State = enum.State + 1;
                b = true;
            end            
        end
        
    end
    
end