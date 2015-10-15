% Generates a single rectangular pulse stimulus.
% See details on the <a href="matlab:web('https://github.com/Symphony-DAS/Symphony/wiki/Standard-Stimulus-Generators#pulsegenerator')">Symphony wiki</a>.

classdef LightStepGenerator < StimulusGenerator
    
    properties (Constant)
        identifier = 'io.github.symphony-das.SchwartzLab.LigthStepGenerator'
        version = 1
    end
    
    properties
        preTime     % Leading duration (ms)
        stimTime    % Pulse duration (ms)
        tailTime    % Trailing duration (ms)
        amplitude   % Pulse amplitude (normalized units: 0-1)
        mean        % Mean amplitude (normalized units: 0-1)
        spotSize    % pixels 
        maskSize    % pixels or 0 for no mask (full screen bg)
    end
    
    methods
        
        function obj = LightStepGenerator(params)
            if nargin == 0
                params = struct();
            end
            
            obj = obj@StimulusGenerator(params);
        end
        
    end
    
    methods (Access = protected)
        
        function presentation = generateStimulus(obj)
            
            
        end
        
    end
    
end