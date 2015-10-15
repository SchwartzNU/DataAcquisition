classdef IOData < Symphony.Core.IIOData
   
    properties
        Time
    end
    
    properties (SetAccess = private)
        Data
        SampleRate
        Duration
    end
    
    methods
        
        function obj = IOData(data, sampleRate)            
            obj.Data = data;
            obj.SampleRate = sampleRate;
            obj.Duration = System.TimeSpan.FromSeconds(obj.Data.Count / obj.SampleRate.Quantity);
        end
        
    end
    
end