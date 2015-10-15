classdef StimulusOutputDataStream < Symphony.Core.IOutputDataStream
    
    properties (SetAccess = private)
        Duration
        Position
        SampleRate
        IsAtEnd
        OutputPosition
        IsOutputAtEnd
    end
    
    properties (Access = private)
        Stimulus
        StimulusDataEnumerator
        UnusedData
    end
    
    methods
        
        function obj = StimulusOutputDataStream(stimulus, blockDuration)
            obj.Stimulus = stimulus;
            obj.StimulusDataEnumerator = stimulus.DataBlocks(blockDuration).GetEnumerator();
            obj.Position = System.TimeSpan.Zero;
            obj.UnusedData = [];
            obj.OutputPosition = System.TimeSpan.Zero;
        end
        
        
        function outData = PullOutputData(obj, duration)
            data = obj.UnusedData;
            
            while isempty(data) || data.Duration < duration
                if ~obj.StimulusDataEnumerator.MoveNext()
                    break;
                end
                
                current = obj.StimulusDataEnumerator.Current;
                
                if isempty(data)
                    data = current;
                else
                    data = data.Concat(current);
                end
            end
            
            [head, rest] = data.SplitData(duration);
            obj.UnusedData = rest;
            
            obj.Position = obj.Position + head.Duration;
            
            outData = head;
        end
        
        
        function d = get.Duration(obj)
            d = obj.Stimulus.Duration;
        end
        
        
        function r = get.SampleRate(obj)
            r = obj.Stimulus.SampleRate;
        end
        
        
        function tf = get.IsAtEnd(obj)
            tf = obj.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && obj.Position >= obj.Duration;
        end
        
        
        function DidOutputData(obj, outputTime, timeSpan, config)
            obj.Stimulus.DidOutputData(outputTime, timeSpan, config);
            
            obj.OutputPosition = obj.OutputPosition + timeSpan;
        end
        
        
        function tf = get.IsOutputAtEnd(obj)
            tf = obj.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && obj.OutputPosition >= obj.Duration;
        end
        
    end
    
end

