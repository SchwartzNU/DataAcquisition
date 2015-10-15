% This class does not actually exist in the core. It is a workaround for MATLAB's slow instantiation of large lists 
% of Measurements.

classdef MeasurementList < handle
    
    properties (SetAccess = private)
        Count
    end
    
    properties (Access = private)
        Items
        ItemCount
        
        Exponent
        BaseUnit
    end
    
    methods
        
        function obj = MeasurementList(array, exponent, baseUnit)
            obj.Items = array;
            obj.ItemCount = length(array);
            
            obj.Exponent = exponent;
            obj.BaseUnit = baseUnit;
        end
        
        
        function AddRange(obj, list)
            if ~strcmp(obj.BaseUnit, list.BaseUnit)
                error('Unit mismatch');
            end
            
            listItems = list.Items * 10 ^ (list.Exponent - obj.Exponent);
            
            obj.Items = [obj.Items(1:obj.ItemCount) listItems];
            obj.ItemCount = obj.ItemCount + list.ItemCount;
        end
        
        
        function c = get.Count(obj)
            c = obj.ItemCount;
        end
        
        
        function l = Concat(obj, other)
            if ~strcmp(obj.BaseUnit, other.BaseUnit)
                error('Unit mismatch');
            end
            
            otherItems = other.Items * 10 ^ (other.Exponent - obj.Exponent);
            
            l = Symphony.Core.MeasurementList([obj.Items(1:obj.ItemCount) otherItems], obj.Exponent, obj.BaseUnit);
        end
        
        
        function l = Take(obj, count)
            l = Symphony.Core.MeasurementList(obj.Items(1:count), obj.Exponent, obj.BaseUnit);
        end
        
        
        function l = Skip(obj, count)
            l = Symphony.Core.MeasurementList(obj.Items(count+1:end), obj.Exponent, obj.BaseUnit);
        end
        
    end
    
    methods (Static)
        
        function a = ToQuantityArray(list)
            a = list.Items;
        end
        
        
        function a = ToBaseUnitQuantityArray(list)
            a = list.Items * 10 ^ list.Exponent;
        end
        
        
        function u = HomogenousBaseUnits(list)
            u = list.BaseUnit;
        end
        
        
        function u = HomogenousDisplayUnits(list)
            m = Symphony.Core.Measurement([], list.Exponent, list.BaseUnit);
            u = m.DisplayUnit;
        end
        
    end
    
end