classdef TimeSpanExtensions
    
    methods (Static)
        
        function s = Samples(timeSpan, sampleRate)
            s = ceil(timeSpan.TotalSeconds * sampleRate.QuantityInBaseUnit);
        end
        
    end
    
end

