classdef ResponseInputDataStream < Symphony.Core.IInputDataStream
    
    properties (SetAccess = private)
        SampleRate
        Duration
        Position
        IsAtEnd
    end
    
    properties (Access = private)
        Response
    end
    
    methods
        
        function obj = ResponseInputDataStream(response, duration)
            obj.Response = response;
            obj.Duration = duration;
            obj.Position = System.TimeSpan.Zero;
        end
        
        
        function PushInputData(obj, inData)
            obj.Response.AppendData(inData);
            
            obj.Position = obj.Position + inData.Duration;
        end
        
        
        function r = get.SampleRate(obj)
            r = obj.Response.SampleRate;
        end
        
        
        function tf = get.IsAtEnd(obj)
            tf = obj.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && obj.Position >= obj.Duration;
        end
                
    end
    
end

