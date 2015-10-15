classdef BackgroundOutputDataStream < Symphony.Core.IOutputDataStream
    
    properties (SetAccess = private)
        Duration
        Position
        SampleRate
        IsAtEnd
        OutputPosition
        IsOutputAtEnd
    end
    
    properties (Access = private)
        Background
    end
    
    methods

        function obj = BackgroundOutputDataStream(background, duration)
            if nargin == 1
                duration = Symphony.Core.TimeSpanOption.Indefinite;
            end
            
            obj.Background = background;
            obj.Duration = duration;
            obj.Position = System.TimeSpan.Zero;
            obj.OutputPosition = System.TimeSpan.Zero;
        end
        
        
        function outData = PullOutputData(obj, duration)
            
            import Symphony.Core.*;
            
            if obj.Duration ~= TimeSpanOption.Indefinite && duration > obj.Duration - obj.Position
                dur = obj.Duration - obj.Position;
            else
                dur = duration;
            end
            
            nSamples = TimeSpanExtensions.Samples(dur, obj.SampleRate);
            value = obj.Background.Value;
            
            data = Symphony.Core.MeasurementList(ones(1,nSamples) * value.QuantityInBaseUnit, 0, value.BaseUnit);
            
            obj.Position = obj.Position + dur;
                        
            outData = OutputData(data, obj.SampleRate, obj.IsAtEnd);
        end       
        
        
        function r = get.SampleRate(obj)
            r = obj.Background.SampleRate;
        end
        
        
        function tf = get.IsAtEnd(obj)
            tf = obj.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && obj.Position >= obj.Duration;
        end
        
        
        function DidOutputData(obj, outputTime, timeSpan, config)
            
            obj.OutputPosition = obj.OutputPosition + timeSpan;
        end
        
        
        function tf = get.IsOutputAtEnd(obj)
            tf = obj.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && obj.OutputPosition >= obj.Duration;
        end
        
    end
    
end

