classdef EventInfo < handle
    
    properties (Access = private)
        Name
    end
    
    methods
        
        function obj = EventInfo(name)
            obj.Name = name;
        end
        
        
        function AddEventHandler(obj, target, handler)
            lh = addlistener(target, obj.Name, handler.Callback);
            
            list = obj.StoredListeners();
            list{end + 1} = lh;
            obj.StoredListeners(list);
        end
        
        
        function RemoveEventHandler(obj, target, handler)
            list = obj.StoredListeners();
            
            for i = 1:length(list)
                l = list{i};
                if l.Source{1} == target && strcmp(l.EventName, obj.Name) && isequal(l.Callback, handler.Callback)
                    delete(l);
                    list(i) = [];
                    break;
                end
            end
            
            obj.StoredListeners(list);
        end
        
    end
    
    methods (Static)
        
        function l = StoredListeners(l)
            persistent stored;
            if nargin > 0
                stored = l;
            end
            l = stored;
        end
        
    end
    
end

