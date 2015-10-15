classdef (InferiorClasses = {?System.TimeSpan}) TimeSpanOption < handle
    
    properties
        Item1
        Item2
    end
    
    methods
        
        function obj = TimeSpanOption(arg1, arg2)            
            if nargin > 1
                obj.Item1 = arg1;
                obj.Item2 = arg2;
            else                
                if isa(arg1, 'Symphony.Core.TimeSpanOption')
                    obj.Item1 = arg1.Item1;
                    obj.Item2 = arg1.Item2;
                else
                    obj.Item1 = true;
                    obj.Item2 = arg1;
                end
            end
        end
        
        %% Operators
        
        function r = minus(a, b)
            a = Symphony.Core.TimeSpanOption(a);
            b = Symphony.Core.TimeSpanOption(b);
            
            r = a.Item2 - b.Item2;
        end
        
        
        function r = ne(a, b)
            r = ~eq(a, b);
        end
        
        
        function r = plus(a, b)
            a = Symphony.Core.TimeSpanOption(a);
            b = Symphony.Core.TimeSpanOption(b);
            
            r = a.Item2 + b.Item2;
        end
        
        
        function r = lt(a, b)
            a = Symphony.Core.TimeSpanOption(a);
            b = Symphony.Core.TimeSpanOption(b);
            
            r = a.Item2 < b.Item2;
        end
        
        
        function r = le(a, b)
            a = Symphony.Core.TimeSpanOption(a);
            b = Symphony.Core.TimeSpanOption(b);
            
            r = a.Item2 <= b.Item2;
        end
        
        
        function r = eq(a, b)
            a = Symphony.Core.TimeSpanOption(a);
            b = Symphony.Core.TimeSpanOption(b);
            
            r = (~a.Item1 && ~b.Item1) || isequal(a, b);
        end
        
        
        function tf = Equals(a, b)
            tf = eq(a, b);
        end
        
        
        function r = gt(a, b)
            a = Symphony.Core.TimeSpanOption(a);
            b = Symphony.Core.TimeSpanOption(b);
            
            r = a.Item2 > b.Item2;
        end
        
        
        function r = ge(a, b)
            a = Symphony.Core.TimeSpanOption(a);
            b = Symphony.Core.TimeSpanOption(b);
            
            r = a.Item2 >= b.Item2;
        end
        
    end
    
    methods (Static)
        
        function obj = Indefinite()
            obj = Symphony.Core.TimeSpanOption(false, NaN);
        end
                
    end
    
end

