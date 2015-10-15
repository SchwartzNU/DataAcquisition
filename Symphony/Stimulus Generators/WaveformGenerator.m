% Generates an arbitrary waveform stimulus from a specified vector.
% See details on the <a href="matlab:web('https://github.com/Symphony-DAS/Symphony/wiki/Standard-Stimulus-Generators#waveformgenerator')">Symphony wiki</a>.

classdef WaveformGenerator < StimulusGenerator
    
    properties (Constant)
        identifier = 'io.github.symphony-das.WaveformGenerator'
        version = 1
    end
    
    properties
        waveshape   % Wave as a vector (units)
        sampleRate  % Sample rate of generated stimulus (Hz)
        units       % Units of generated stimulus
    end
    
    methods
        
        function obj = WaveformGenerator(params)
            if nargin == 0
                params = struct();
            end
            
            obj = obj@StimulusGenerator(params);
        end
        
    end
    
    methods (Access = protected)
        
        function stim = generateStimulus(obj)
            import Symphony.Core.*;
            
            measurements = Measurement.FromArray(obj.waveshape, obj.units);
            rate = Measurement(obj.sampleRate, 'Hz');
            output = OutputData(measurements, rate);
            
            params = obj.stimulusParameters;
            params.Remove('waveshape');
            stim = RenderedStimulus(obj.identifier, params, output);
        end
        
    end
    
end