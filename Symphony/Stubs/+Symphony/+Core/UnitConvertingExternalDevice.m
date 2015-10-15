classdef UnitConvertingExternalDevice < Symphony.Core.ExternalDeviceBase
   
    properties
        MeasurementConversionTarget
    end
    
    methods
        
        function obj = UnitConvertingExternalDevice(name, manufacturer, controller, background)
            obj = obj@Symphony.Core.ExternalDeviceBase(name, manufacturer, controller, background);
        end
               
        
        function outData = PullOutputData(obj, stream, duration) %#ok<INUSL>
            outData = obj.Controller.PullOutputData(obj, duration);
        end
        
        
        function PushInputData(obj, stream, inData) %#ok<INUSL>
            obj.Controller.PushInputData(obj, inData);
        end
        
    end
end