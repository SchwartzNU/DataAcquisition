classdef SequenceOutputDataStream < Symphony.Core.IOutputDataStream
    
    properties (SetAccess = private)
        SampleRate
        Duration
        Position
        IsAtEnd
        OutputPosition
        IsOutputAtEnd
    end
    
    properties (Access = private)
        UnendedStreams
        EndedStreams
    end
    
    methods
        
        function obj = SequenceOutputDataStream()
            obj.UnendedStreams = System.Collections.Queue();
            obj.EndedStreams = System.Collections.Queue();
        end
        
        
        function Add(obj, stream)
            obj.UnendedStreams.Enqueue(stream);
        end
        
        
        function tf = get.IsAtEnd(obj)
            tf = obj.UnendedStreams.Count == 0;
        end
        
        
        function outData = PullOutputData(obj, duration)
            
            data = [];
            
            while obj.UnendedStreams.Count > 0 && (isempty(data) || data.Duration < duration)
                stream = obj.UnendedStreams.Peek();
                
                if isempty(data)
                    data = stream.PullOutputData(duration);
                else
                    data = data.Concat(stream.PullOutputData(duration - data.Duration));
                end
                
                if stream.IsAtEnd
                    obj.EndedStreams.Enqueue(obj.UnendedStreams.Dequeue());
                end
            end
            
            outData = data;
        end
        
        
        function r = get.SampleRate(obj)
            r = obj.UnendedStreams.Peek().SampleRate;
        end
        
        
        function p = get.Position(obj)
            p = obj.UnendedStreams.Peek().Position;
        end
        
        
        function p = get.OutputPosition(obj)
            if obj.EndedStreams.Count > 0
                p = obj.EndedStreams.Peek().OutputPosition;
            elseif obj.UnendedStreams.Count > 0
                p = obj.UnendedStreams.Peek().OutputPosition;
            else
                p = System.TimeSpan.Zero;
            end
        end
        
        
        function tf = get.IsOutputAtEnd(obj)
            tf = obj.EndedStreams.Count == 0 && obj.UnendedStreams.Count == 0;
        end
        
        
        function d = get.Duration(obj)
            d = System.TimeSpan.Zero;
            
            itr = obj.UnendedStreams.GetEnumerator();
            while itr.MoveNext()
                stream = itr.Current;
                
                if stream.Duration == Symphony.Core.TimeSpanOption.Indefinite
                    d = Symphony.Core.TimeSpanOption.Indefinite;
                    break;
                end
                
                d = d + stream.Duration;
            end                    
        end
        
        
        function DidOutputData(obj, outputTime, timeSpan, config)
            
            while timeSpan > System.TimeSpan.Zero
                if obj.EndedStreams.Count > 0
                    stream = obj.EndedStreams.Peek();
                else
                    stream = obj.UnendedStreams.Peek();
                end
                
                if stream.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && timeSpan > stream.Duration - stream.OutputPosition
                    span = stream.Duration - stream.OutputPosition;
                else
                    span = timeSpan;
                end
                
                stream.DidOutputData(outputTime, span, config);
                
                timeSpan = timeSpan - span;
                
                if stream.IsOutputAtEnd
                    obj.EndedStreams.Dequeue();
                end
            end
        end
        
    end
    
end

