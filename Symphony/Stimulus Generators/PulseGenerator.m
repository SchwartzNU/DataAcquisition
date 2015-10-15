% Generates a single rectangular pulse stimulus.
% See details on the <a href="matlab:web('https://github.com/Symphony-DAS/Symphony/wiki/Standard-Stimulus-Generators#pulsegenerator')">Symphony wiki</a>.

classdef PulseGenerator < StimulusGenerator
    
    properties (Constant)
        identifier = 'io.github.symphony-das.PulseGenerator'
        version = 1
    end
    
    properties
        preTime     % Leading duration (ms)
        stimTime    % Pulse duration (ms)
        tailTime    % Trailing duration (ms)
        amplitude   % Pulse amplitude (units)
        mean        % Mean amplitude (units)
        sampleRate  % Sample rate of generated stimulus (Hz)
        units       % Units of generated stimulus
    end
    
    methods
        
        function obj = PulseGenerator(params)
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
            data(prePts + 1:prePts + stimPts) = obj.amplitude + obj.mean;
            
            measurements = Measurement.FromArray(data, obj.units);
            rate = Measurement(obj.sampleRate, 'Hz');
            output = OutputData(measurements, rate);
            
            stim = RenderedStimulus(obj.identifier, obj.stimulusParameters, output);
        end
        
    end
    
end