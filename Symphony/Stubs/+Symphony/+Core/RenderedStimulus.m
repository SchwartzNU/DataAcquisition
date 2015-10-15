classdef RenderedStimulus < Symphony.Core.Stimulus
    
    properties (Access = private)
        Data
    end
        
    methods
        
        function obj = RenderedStimulus(stimulusID, parameters, data, duration)
            obj = obj@Symphony.Core.Stimulus(stimulusID, Symphony.Core.Measurement.HomogenousBaseUnits(data.Data), parameters);
            
            if nargin < 4
                duration = Symphony.Core.TimeSpanOption(data.Duration);
            end
            
            obj.Data = data;
            obj.Duration = duration;
            obj.SampleRate = data.SampleRate;
        end
        
        
        function enumerable = DataBlocks(obj, blockDuration)
            enumerable = Enumerable(@GetEnumerator);
            
            function enum = GetEnumerator()
                enum = Enumerator(@MoveNext);
                enum.State.local = obj.Data;
                enum.State.index = System.TimeSpan.Zero();
                
                function b = MoveNext()
                    enum.Current = [];
                    local = enum.State.local;
                    index = enum.State.index;

                    isIndefinite = obj.Duration == Symphony.Core.TimeSpanOption.Indefinite();

                    if ~isIndefinite && index >= obj.Duration
                        b = false;
                        return;
                    end

                    if isIndefinite || blockDuration <= obj.Duration - index
                        dur = blockDuration;
                    else
                        dur = obj.Duration - index;
                    end

                    while (local.Duration < dur)
                        local = local.Concat(obj.Data);
                    end

                    [head, rest] = local.SplitData(dur);
                    local = rest;

                    index = index + dur;

                    enum.Current = Symphony.Core.OutputData(head.Data, head.SampleRate, ~isIndefinite && index >= obj.Duration);
                    enum.State.local = local;
                    enum.State.index = index;
                    b = true;
                end
            end
        end
        
    end
    
end