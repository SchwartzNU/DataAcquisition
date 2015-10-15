% Generates a square wave stimulus.
% See details on the <a href="matlab:web('https://github.com/Symphony-DAS/Symphony/wiki/Standard-Stimulus-Generators#squaregenerator')">Symphony wiki</a>.

classdef SquareGenerator < StimulusGenerator
    
    properties (Constant)
        identifier = 'io.github.symphony-das.SquareGenerator'
        version = 1
    end
    
    properties
        preTime     % Leading duration (ms)
        stimTime    % Square wave duration (ms)
        tailTime    % Trailing duration (ms)
        amplitude   % Square wave amplitude (units)
        period      % Square wave period (ms)
        phase = 0   % Square wave phase offset (radians)
        mean        % Mean amplitude (units)
        sampleRate  % Sample rate of generated stimulus (Hz)
        units       % Units of generated stimulus
    end
    
    methods
        
        function obj = SquareGenerator(params)
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
            sine = sin(freq * time + obj.phase);
            
            square(sine > 0) = obj.amplitude;
            square(sine < 0) = -obj.amplitude;
            square = square + obj.mean;
            
            data(prePts + 1:prePts + stimPts) = square;
            
            measurements = Measurement.FromArray(data, obj.units);
            rate = Measurement(obj.sampleRate, 'Hz');
            output = OutputData(measurements, rate);
            
            stim = RenderedStimulus(obj.identifier, obj.stimulusParameters, output);
        end
        
    end
    
end