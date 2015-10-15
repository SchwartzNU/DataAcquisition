classdef InputData < Symphony.Core.IOData
   
    properties
        InputTime
    end
    
    methods
        
        function obj = InputData(data, sampleRate, inputTime)           
            obj = obj@Symphony.Core.IOData(data, sampleRate);
            
            obj.InputTime = inputTime;
        end
        
        
        function [head, rest] = SplitData(obj, duration)
            if duration.Ticks == 0
                requestedSamples = 0;
            else
                requestedSamples = round(duration.TotalSeconds * obj.SampleRate.QuantityInBaseUnit);
            end
            
            numSamples = min(requestedSamples, obj.Data.Count);
            
            headData = obj.Data.Take(numSamples);
            restData = obj.Data.Skip(numSamples).Take(obj.Data.Count - numSamples);
            
            head = Symphony.Core.InputData(headData, obj.SampleRate, obj.InputTime);
            rest = Symphony.Core.InputData(restData, obj.SampleRate, obj.InputTime);           
        end
        
    end
    
end