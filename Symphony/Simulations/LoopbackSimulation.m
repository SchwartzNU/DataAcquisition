% Returns all stimuli on output channels as responses on corresponding input channels (e.g. a stimulus on ANALOG_OUT.1 
% will return as a response on ANALOG_IN.1). Noise is simulated for input channels with no associated output channel.

classdef LoopbackSimulation < Simulation
    
    methods
        
        function input = runner(obj, output, timeStep)
            import Symphony.Core.*;

            % Create the input Dictionary to return.
            input = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IDAQInputStream', 'Symphony.Core.IInputData'});

            % Get all input streams (i.e. channels) associated with the DAQ controller.
            inputStreams = NET.invokeGenericMethod('System.Linq.Enumerable', 'ToList', ...
                {'Symphony.Core.IDAQInputStream'}, obj.daqController.InputStreams);

            % Loop through all input streams.
            inStreamEnum = inputStreams.GetEnumerator();
            while inStreamEnum.MoveNext()
                inStream = inStreamEnum.Current;
                inData = [];

                if ~inStream.Active
                    % We don't care to process inactive input streams (i.e. channels without devices).
                    continue;
                end

                % Find the corresponding output data and make it into input data.
                outStreamEnum = output.Keys.GetEnumerator();
                while outStreamEnum.MoveNext()
                    outStream = outStreamEnum.Current;

                    if strcmp(char(outStream.Name), strrep(char(inStream.Name), '_IN.', '_OUT.'))
                        outData = output.Item(outStream);
                        inData = InputData(outData.Data, outData.SampleRate, obj.daqController.Clock.Now);
                        break;
                    end
                end

                % If there was no corresponding output, simulate noise.
                if isempty(inData)
                    samples = Symphony.Core.TimeSpanExtensions.Samples(timeStep, inStream.SampleRate);
                    noise = Measurement.FromArray(rand(1, samples) - 0.5, 'mV');
                    inData = InputData(noise, inStream.SampleRate, obj.daqController.Clock.Now);
                end

                input.Add(inStream, inData);
            end
        end
        
    end
    
end