% Generates a sine wave stimulus.
% See details on the <a href="matlab:web('https://github.com/Symphony-DAS/Symphony/wiki/Standard-Stimulus-Generators#sinegenerator')">Symphony wiki</a>.

classdef SineGenerator < StimulusGenerator
    
    properties (Constant)
        identifier = 'io.github.symphony-das.SineGenerator'
        version = 1
    end
    
    properties
        preTime     % Leading duration (ms)
        stimTime    % Sine wave duration (ms)
        tailTime    % Trailing duration (ms)
        amplitude   % Sine wave amplitude (units)
        period      % Sine wave period (ms)
        phase = 0   % Sine wave phase offset (radians)
        mean        % Mean amplitude (units)
        sampleRate  % Sample rate of generated stimulus (Hz)
        units       % Units of generated stimulus
    end
    
    methods
        
        function obj = SineGenerator(params)
            if nargin == 0
                params = struct();
            end
            
            obj = obj@StimulusGenerator(params);
        end
        
    end
    
    methods (Access = protected)
        
        function stim = generateStimulus(obj)
            import Symphony.Core.*;
            
            timeToPts = @(t)(round(t / 1e3 * obj.sampleRate));
            
            prePts = timeToPts(obj.preTime);
            stimPts = timeToPts(obj.stimTime);
            tailPts = timeToPts(obj.tailTime);
            
            data = ones(1, prePts + stimPts + tailPts) * obj.mean;
            
            freq = 2 * pi / (obj.period * 1e-3);
            time = (0:stimPts-1) / obj.sampleRate;
            sine = obj.mean + obj.amplitude * sin(freq * time + obj.phase);
            
            data(prePts + 1:prePts + stimPts) = sine;
            
            measurements = Measurement.FromArray(data, obj.units);
            rate = Measurement(obj.sampleRate, 'Hz');
            output = OutputData(measurements, rate);
            
            stim = RenderedStimulus(obj.identifier, obj.stimulusParameters, output);
        end
        
    end
    
end