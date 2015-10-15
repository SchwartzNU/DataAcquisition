classdef Response < handle
   
    properties (SetAccess = private)
        Data
        DataSegments
        DataConfigurationSpans
        SampleRate
        InputTime
        Duration
    end
    
    methods
        
        function obj = Response()            
            obj.DataSegments = System.Collections.ArrayList();
            obj.DataConfigurationSpans = System.Collections.ArrayList();
            
            % TODO: This should be a getter and should return a DateTimeOffset
            obj.InputTime = now;
        end
        
        
        function AppendData(obj, data)
            obj.DataSegments.Add(data);
        end  
        
        
        function d = get.Data(obj)
            import Symphony.Core.*;
            
            d = MeasurementList([],[],[]);
            
            for i = 0:obj.DataSegments.Count-1
                if i == 0
                    d = obj.DataSegments.Item(i).Data;
                else
                    d.AddRange(obj.DataSegments.Item(i).Data);
                end
            end
            
            % To keep the response units consistent we'll always return them in base units.
            % This is necessary because we're using MeasurementList instead a true list of Measurement.
            array = MeasurementList.ToBaseUnitQuantityArray(d);
            units = MeasurementList.HomogenousBaseUnits(d);
            d = MeasurementList(array, 0, units);
        end
        
        
        function d = get.Duration(obj)
            d = System.TimeSpan.Zero();
            
            for i = 0:obj.DataSegments.Count-1
                d = d + obj.DataSegments.Item(i).Duration;
            end
        end
        
        
        function s = get.SampleRate(obj)
            s = obj.DataSegments.Item(0).SampleRate;
        end
        
    end
    
end