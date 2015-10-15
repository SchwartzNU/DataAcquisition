classdef LcrStageClient < StageClient
    
    methods
        
        % Gets the remote LightCrafter bit depth, color, and number of patterns.
        function [bitDepth, color, numPatterns] = getLcrPatternAttributes(obj)
            obj.sendEvent(LcrNetEvents.GET_LCR_PATTERN_ATTRIBUTES);
            [bitDepth, color, numPatterns] = obj.getResponse();
        end
        
        % Sets the remote LightCrafter bit depth, color, and optionally number of patterns. If the number of patterns is
        % not specified the maximum number of patterns for the given bit depth will be used (i.e. the highest pattern
        % rate).
        function setLcrPatternAttributes(obj, bitDepth, color, numPatterns)
            if nargin < 4
                numPatterns = [];
            end
            
            obj.sendEvent(LcrNetEvents.SET_LCR_PATTERN_ATTRIBUTES, bitDepth, color, numPatterns);
            obj.getResponse();
        end
        
        % Gets the remote LightCrafter LED currents.
        function [red, green, blue] = getLcrLedCurrents(obj)
            obj.sendEvent(LcrNetEvents.GET_LCR_LED_CURRENTS);
            [red, green, blue] = obj.getResponse();
        end
        
        % Sets the remote LightCrafter LED currents.
        function setLcrLedCurrents(obj, red, green, blue)
            obj.sendEvent(LcrNetEvents.SET_LCR_LED_CURRENTS, red, green, blue);
            obj.getResponse();
        end
                       
    end
    
end