% A stub class to support MATLAB style arrays of .NET types.

classdef Array < handle
    
    properties (Access = private)
        Items
        ItemType
    end
    
    methods
        
        function obj = Array(itemType, varargin)
            obj = obj@handle();
            
            if numel(varargin) == 1
                obj.Items = cell(1, varargin{1});
            else
                obj.Items = cell(varargin{:});
            end
            obj.ItemType = itemType;
        end
        
        
        function s = size(obj)
            s = size(obj.Items);
        end
        
        
        function n = numel(obj)
            n = numel(obj.Items);
        end
        
        
        function obj = subsasgn(obj, s, val)
            % TODO: make sure val is compatible with obj.ItemType?
            
            if isempty(s) && strcmp(class(val),'Array')
                % When would this ever happen? copy constructor? untested...
                obj = NETArray(val.itemType, 0);
                obj.Items = val.items;
            end
            
            switch s(1).type
                case '.'
                    % Use the built-in subsasagn for dot notation
                    obj = builtin('subsasgn', obj, s, val);
                case '()'
                    if length(s) < 2
                        if strcmp(class(val), 'Array')
                            error('NETArray:subsasgn', 'Object must be scalar')
                        else
                          snew = substruct('.', 'Items', '{}', s(1).subs(:));
                          obj = subsasgn(obj, snew, val);
                        end
                    end
                case '{}'
                    error('NETArray:subsasgn', 'Not a supported subscripted assignment')
            end     
        end
    
        
        function sref = subsref(obj,s)
            switch s(1).type
                % Use the built-in subsref for dot notation
                case '.'
                    sref = builtin('subsref', obj, s);
                case '()'
                    if length(s) < 2
                        sref = builtin('subsref', obj.Items, s);
                        if iscell(sref)
                            sref = sref{1};
                        end
                    else
                        sref = builtin('subsref', obj, s);
                    end
                case '{}'
                    error('NETArray:subsref', 'Not a supported subscripted reference')
            end 
        end
        
    end
end