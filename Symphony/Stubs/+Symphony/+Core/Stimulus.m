classdef Stimulus < handle
    
    properties (SetAccess = protected)
        StimulusID
        Units
        Parameters
        Duration
        SampleRate
        IsComplete
    end
    
    properties (Access = private)
        Position
    end
    
    methods
        
        function obj = Stimulus(id, units, params)
            obj.StimulusID = id;
            obj.Units = units;
            obj.Parameters = params;
            
            obj.Position = System.TimeSpan.Zero;
        end
        
        
        function DidOutputData(obj, outputTime, timeSpan, config)
            obj.Position = obj.Position + timeSpan;
        end
                            
            
        function tf = get.IsComplete(obj)
            tf = obj.Duration ~= Symphony.Core.TimeSpanOption.Indefinite && obj.Position >= obj.Duration;
        end
        
        
        function r = isequal(a, b)
            if a == b
                r = 1;
            else
                r = 0;
            end
        end
        
    end
    
end

