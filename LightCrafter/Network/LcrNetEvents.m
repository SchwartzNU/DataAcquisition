classdef LcrNetEvents
    
    properties (Constant)
        %% Client to server:
        % Requests the current LightCrafter pattern bit depth, color, and number of patterns.
        GET_LCR_PATTERN_ATTRIBUTES = 'GET_LCR_PATTERN_ATTRIBUTES'
        
        % Requests a new LightCrafter pattern bit depth, color, and number of patterns.
        SET_LCR_PATTERN_ATTRIBUTES = 'SET_LCR_PATTERN_ATTRIBUTES'
        
        % Requests the current LightCrafter LED current settings.
        GET_LCR_LED_CURRENTS = 'GET_LCR_LED_CURRENTS'
        
        % Requests new LightCrafter LED current settings.
        SET_LCR_LED_CURRENTS = 'SET_LCR_LED_CURRENTS'
    end
    
end