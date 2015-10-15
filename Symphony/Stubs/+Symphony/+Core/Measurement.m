classdef Measurement < handle
   
    properties (SetAccess = private)
        Quantity
        Exponent
        BaseUnit
    end
    
    properties (Dependent, SetAccess = private)
        DisplayUnit
    end
    
    properties (Constant)
        UNITLESS = '_unitless_';
    end
    
    properties (Constant, Access = private)
        BaseUnits = {'Y', 'Z', 'E', 'P', 'T', 'G', 'M', 'k', 'h', 'da', 'd', 'c', 'm', 'µ', 'n', 'p', 'f', 'a', 'z', 'y', ''};
        BaseExps = [24, 21, 18, 15, 12, 9, 6, 3, 2, 1, -1, -2, -3, -6, -9, -12, -15, -18, -21, -24, 0];
    end
        
    methods
        
        function obj = Measurement(quantity, arg1, arg2)
            if nargin == 0
                % For preallocating arrays.
                return;
            end
            
            obj.Quantity = quantity;

            if nargin == 2
                % e.g. Measurement(10, 'mV')
                [obj.BaseUnit, obj.Exponent] = splitUnit(arg1);
            elseif nargin == 3
                % e.g. Measurement(10, -3, 'V')
                if ~ismember(arg1, Symphony.Core.Measurement.BaseExps)
                    error('Symphony:Core:Measurement', 'Unknown measurement exponent: %d', arg1);
                end
                obj.Exponent = arg1;
                obj.BaseUnit = arg2;
            end
        end
        
        
        function q = QuantityInBaseUnit(obj)
            q = obj.Quantity * 10 ^ obj.Exponent;
        end
        
        
        function du = get.DisplayUnit(obj)
            expInd = Symphony.Core.Measurement.BaseExps == obj.Exponent;
            du = [Symphony.Core.Measurement.BaseUnits{expInd} obj.BaseUnit];
        end
        
        
        function tf = Equals(obj, other)
            tf = strcmp(obj.BaseUnit, other.BaseUnit) && obj.QuantityInBaseUnit == other.QuantityInBaseUnit;
        end
        
    end
    
    
    methods (Static)
        
        function m = FromArray(array, unit)
            [baseUnit, exponent] = splitUnit(unit);
            
            m = Symphony.Core.MeasurementList(array, exponent, baseUnit);
        end
        
        
        function a = ToQuantityArray(list)
            if isa(list, 'Symphony.Core.MeasurementList')
                a = Symphony.Core.MeasurementList.ToQuantityArray(list);
                return;
            end
            
            a = zeros(1, list.Count);
            for i = 1:list.Count
                a(i) = list.Item(i-1).Quantity;
            end
        end
        
        
        function a = ToBaseUnitQuantityArray(list)
            if isa(list, 'Symphony.Core.MeasurementList')
                a = Symphony.Core.MeasurementList.ToBaseUnitQuantityArray(list);
                return;
            end
            
            a = zeros(1, list.Count);
            for i = 1:list.Count
                a(i) = list.Item(i-1).QuantityInBaseUnit;
            end
        end
        
        
        function u = HomogenousBaseUnits(list)
            if isa(list, 'Symphony.Core.MeasurementList')
                u = Symphony.Core.MeasurementList.HomogenousBaseUnits(list);
                return;
            end
            
            u = list.Item(0).BaseUnit;
        end
        
        
        function u = HomogenousDisplayUnits(list)
            if isa(list, 'Symphony.Core.MeasurementList')
                u = Symphony.Core.MeasurementList.HomogenousDisplayUnits(list);
                return;
            end
            
            u = list.Item(0).DisplayUnit;
        end
        
    end
    
end


function [u, e] = splitUnit(unitString)
    if length(unitString) < 2
        u = unitString;
        e = 0;
        return
    end
    
    for i = 1:length(Symphony.Core.Measurement.BaseUnits)
        baseUnit = Symphony.Core.Measurement.BaseUnits{i};
        if strncmp(unitString, baseUnit, length(baseUnit)) && length(unitString) > length(baseUnit)
            u = unitString(length(baseUnit) + 1:end);
            e = Symphony.Core.Measurement.BaseExps(i);
            return
        end
    end
    
    error('Symphony:Core:Measurement', 'Unknown measurement units %s', unitString);
end
