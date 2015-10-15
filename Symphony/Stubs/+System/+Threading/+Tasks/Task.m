classdef Task < handle
    
    properties (SetAccess = private)
        IsFaulted
        Exception
    end
    
    properties (Access = private)
        Action
    end
    
    methods
        
        function obj = Task(action)
            obj.IsFaulted = false;
            obj.Action = action;
        end
        
        
        function Start(obj)
            try
                obj.Action();
            catch x
                obj.IsFaulted = true;
                obj.Exception = System.AggregateException(getReport(x, 'extended', 'hyperlinks', 'off'));
            end
        end        
        
    end
    
end

