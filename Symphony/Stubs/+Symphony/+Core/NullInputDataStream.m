classdef NullInputDataStream < Symphony.Core.IInputDataStream
    
    properties (SetAccess = private)
        SampleRate
        Duration
        Position
        IsAtEnd
    end
    
    methods
        
        function obj = NullInputDataStream(duration)
            if nargin == 0
                duration = Symphony.Core.TimeSpanOption.Indefinite;
            end
            
            obj.Duration = duration;
            obj.Position = System.TimeSpan.Zero;
        end
        
        
        function r = get.SampleRate(obj)
            r = [];
        end
        
        
        function tf = get.IsAtEnd(obj)
            tf = obj.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && obj.Position >= obj.Duration;
        end
        
        
        function PushInputData(obj, inData)
            obj.Position = obj.Position + inData.Duration;
        end
        
    end
    
end

