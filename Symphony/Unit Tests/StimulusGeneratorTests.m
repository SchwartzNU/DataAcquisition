classdef StimulusGeneratorTests < matlab.unittest.TestCase
    
    methods (TestClassSetup)
        
        function classSetup(testCase)
            import matlab.unittest.fixtures.PathFixture;
            
            testPath = mfilename('fullpath');
            symphonyDir = fullfile(fileparts(testPath), '..');
            generatorsDir = fullfile(symphonyDir, 'Stimulus Generators');
            utilitiesDir = fullfile(symphonyDir, 'Utilities');
            
            testCase.applyFixture(PathFixture(symphonyDir));
            testCase.applyFixture(PathFixture(generatorsDir));
            testCase.applyFixture(PathFixture(utilitiesDir));
            
            addSymphonyAssembly('Symphony.Core');
        end
        
    end
    
    methods (Test)
        
        %% PulseGenerator
        
        function pulseId(testCase)
            testCase.verifyId(PulseGenerator);
        end
        
        
        function generatesPulse(testCase)
            p = makePulseParams();
            gen = PulseGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            
            [prePts, stimPts, tailPts] = getPts(p);
            stimData = getStimData(stim);
            
            testCase.verifyEqual(length(stimData), prePts+stimPts+tailPts);
            testCase.verifyEveryElementEqualTo(stimData(1:prePts), p.mean);
            testCase.verifyEveryElementEqualTo(stimData(prePts+1:prePts+stimPts), p.amplitude + p.mean);
            testCase.verifyEveryElementEqualTo(stimData(prePts+stimPts+1:end), p.mean);
        end
        
        
        function regeneratesPulse(testCase)
            p = makePulseParams();
            gen = PulseGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusRegenerates(stim);
        end
        
        
        %% RepeatingPulseGenerator
        
        function repeatingPulseId(testCase)
            testCase.verifyId(RepeatingPulseGenerator);
        end
        
        
        function generatesRepeatingPulse(testCase)
            p = makePulseParams();
            gen = RepeatingPulseGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            testCase.verifyTrue(stim.Duration.Equals(Symphony.Core.TimeSpanOption.Indefinite));
            
            [prePts, stimPts, tailPts] = getPts(p);
            totalPts = prePts + stimPts + tailPts;
            
            nTest = 3;
            stimData = getStimData(stim, System.TimeSpan.FromMilliseconds(nTest * (p.preTime + p.stimTime + p.tailTime)));
            
            for i = 0:nTest-1
                data = stimData(totalPts*i+1:totalPts*(i+1));
                
                testCase.verifyEveryElementEqualTo(data(1:prePts), p.mean);
                testCase.verifyEveryElementEqualTo(data(prePts+1:prePts+stimPts), p.amplitude + p.mean);
                testCase.verifyEveryElementEqualTo(data(prePts+stimPts+1:end), p.mean);
            end
        end
        
        
        function regeneratesRepeatingPulse(testCase)
            p = makePulseParams();
            gen = RepeatingPulseGenerator(p);
            stim = gen.generate();
            
            nTest = 3;
            testCase.verifyStimulusRegenerates(stim, System.TimeSpan.FromMilliseconds(nTest * (p.preTime + p.stimTime + p.tailTime)));
        end
        
        
        %% RampGenerator
        
        function rampId(testCase)
            testCase.verifyId(RampGenerator);
        end
        
        
        function generatesRamp(testCase)
            p = makeRampParams();
            gen = RampGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            
            [prePts, stimPts, tailPts] = getPts(p);
            stimData = getStimData(stim);
            
            testCase.verifyEqual(length(stimData), prePts+stimPts+tailPts);
            testCase.verifyEveryElementEqualTo(stimData(1:prePts), p.mean);
            testCase.verifyEqual(stimData(prePts+1:prePts+stimPts), linspace(0, p.amplitude, stimPts) + p.mean, 'AbsTol', 1e-12);
            testCase.verifyEveryElementEqualTo(stimData(prePts+stimPts+1:end), p.mean);
        end
        
        
        function regeneratesRamp(testCase)
            p = makeRampParams();
            gen = RampGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusRegenerates(stim);
        end
        
        
        %% SineGenerator
        
        function sineId(testCase)
            testCase.verifyId(SineGenerator());
        end
        
        
        function generatesSine(testCase)
            p = makeSineParams();
            gen = SineGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            
            [prePts, stimPts, tailPts] = getPts(p);
            freq = 2 * pi / (p.period * 1e-3);
            time = (0:stimPts-1) / p.sampleRate;
            stimData = getStimData(stim);
            
            testCase.verifyEqual(length(stimData), prePts+stimPts+tailPts);
            testCase.verifyEveryElementEqualTo(stimData(1:prePts), p.mean);
            testCase.verifyEqual(stimData(prePts+1:prePts+stimPts), p.mean + p.amplitude * sin(freq * time + p.phase), 'AbsTol', 1e-12);
            testCase.verifyEveryElementEqualTo(stimData(prePts+stimPts+1:end), p.mean);
        end
        
        
        function regeneratesSine(testCase)
            p = makeSineParams();
            gen = SineGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusRegenerates(stim);
        end
        
        
        %% SquareGenerator
        
        function squareId(testCase)
            testCase.verifyId(SquareGenerator());
        end
        
        
        function generatesSquare(testCase)
            p = makeSquareParams();
            gen = SquareGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            
            [prePts, stimPts, tailPts] = getPts(p);
            freq = 2 * pi / (p.period * 1e-3);
            time = (0:stimPts-1) / p.sampleRate;
            sine = sin(freq * time + p.phase);
            square(sine > 0) = p.amplitude;
            square(sine < 0) = -p.amplitude;
            square = square + p.mean;
            
            stimData = getStimData(stim);
            
            testCase.verifyEqual(length(stimData), prePts+stimPts+tailPts);
            testCase.verifyEveryElementEqualTo(stimData(1:prePts), p.mean);
            testCase.verifyEqual(stimData(prePts+1:prePts+stimPts), square, 'AbsTol', 1e-12);
            testCase.verifyEveryElementEqualTo(stimData(prePts+stimPts+1:end), p.mean);
        end
        
        
        function regeneratesSquare(testCase)
            p = makeSquareParams();
            gen = SquareGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusRegenerates(stim);
        end
        
        
        %% PulseTrainGenerator
        
        function pulseTrainId(testCase)
            testCase.verifyId(PulseTrainGenerator());
        end
        
        
        function generatesPulseTrain(testCase)
            p = makePulseTrainParams();
            gen = PulseTrainGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            
            stimData = getStimData(stim);
            
            remainingData = stimData;
            
            prePts = toPts(p.preTime, p.sampleRate);
            pre = remainingData(1:prePts);
            remainingData = remainingData(prePts+1:end);
            
            testCase.verifyEveryElementEqualTo(pre, p.mean);
            
            for i = 0:p.numPulses-1
                pulsePts = toPts(p.pulseTimeIncrement * i + p.pulseTime, p.sampleRate);                
                pulse = remainingData(1:pulsePts);
                remainingData = remainingData(pulsePts+1:end);
                
                testCase.verifyEveryElementEqualTo(pulse, p.mean + p.amplitude + p.amplitudeIncrement * i);
                
                if i < p.numPulses-1
                    intervalPts = toPts(p.intervalTimeIncrement * i + p.intervalTime, p.sampleRate);
                    interval = remainingData(1:intervalPts);
                    remainingData = remainingData(intervalPts+1:end);
                    
                    testCase.verifyEveryElementEqualTo(interval, p.mean);
                end
            end
            
            tailPts = toPts(p.tailTime, p.sampleRate);
            tail = remainingData(1:tailPts);
            remainingData = remainingData(tailPts+1:end);
            
            testCase.verifyEveryElementEqualTo(tail, p.mean);
            
            testCase.verifyEqual(length(remainingData), 0);
        end
        
        
        function regeneratesPulseTrain(testCase)
            p = makePulseTrainParams();
            gen = PulseTrainGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusRegenerates(stim);
        end
        
        
        %% WaveformGenerator
        
        function waveformId(testCase)
            testCase.verifyId(WaveformGenerator());
        end
        
        
        function generatesWaveform(testCase)
            p = makeWaveformParams();
            gen = WaveformGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, stim);
            testCase.verifyEqual(System.Decimal.ToDouble(stim.SampleRate.QuantityInBaseUnit), gen.sampleRate);
            testCase.verifyEqual(char(stim.SampleRate.BaseUnit), 'Hz');
            testCase.verifyEqual(char(stim.Units), gen.units);
            
            stimData = getStimData(stim);
            
            testCase.verifyEqual(stimData, p.waveshape, 'AbsTol', 1e-12);
        end
        
        
        function regeneratesWaveform(testCase)
            p = makeWaveformParams();
            gen = WaveformGenerator(p);
            stim = gen.generate();
            
            testCase.verifyStimulusRegenerates(stim);
        end
        
        
        %% SumGenerator
        
        function sumId(testCase)
            testCase.verifyId(SumGenerator());
        end
        
        
        function generatesSum(testCase)
            p1 = makePulseParams();
            gen1 = PulseGenerator(p1);
            stim1 = gen1.generate();
            
            [prePts, stimPts, tailPts] = getPts(p1);
            
            p2.waveshape = 1:prePts+stimPts+tailPts;
            p2.sampleRate = p1.sampleRate;
            p2.units = p1.units;
            gen2 = WaveformGenerator(p2);
            stim2 = gen2.generate();
            
            stim3 = gen2.generate();
            
            p.stimuli = {stim1, stim2, stim3};
            gen = SumGenerator(p);
            sumStim = gen.generate();
            
            testCase.verifyStimulusAttributes(gen, sumStim);
            
            stim1Data = getStimData(stim1);
            stim2Data = getStimData(stim2);
            stim3Data = getStimData(stim3);
            sumData = getStimData(sumStim);
            
            testCase.verifyEqual(sumData, stim1Data + stim2Data + stim3Data, 'AbsTol', 1e-12);
        end
        
        
        function regeneratesSum(testCase)
            p1 = makePulseParams();
            gen1 = PulseGenerator(p1);
            stim1 = gen1.generate();
            
            [prePts, stimPts, tailPts] = getPts(p1);
            
            p2.waveshape = 1:prePts+stimPts+tailPts;
            p2.sampleRate = p1.sampleRate;
            p2.units = p1.units;
            gen2 = WaveformGenerator(p2);
            stim2 = gen2.generate();
            
            stim3 = gen2.generate();
            
            p.stimuli = {stim1, stim2, stim3};
            gen = SumGenerator(p);
            sum = gen.generate();
            
            testCase.verifyStimulusRegenerates(sum);
        end
        
    end
    
    methods
        
        function verifyEveryElementEqualTo(testCase, array, value)
            import matlab.unittest.constraints.*;
            testCase.verifyThat(EveryElementOf(array), IsEqualTo(value, 'Within', AbsoluteTolerance(1e-12)));
        end
        
        
        function verifyId(testCase, gen)
            split = regexp(gen.identifier, '\.', 'split');
            testCase.verifyEqual(split{end}, class(gen));
        end
        
        
        function verifyStimulusAttributes(testCase, gen, stim)
            testCase.verifyEqual(char(stim.StimulusID), gen.identifier);
            testCase.verifyEqual(stim.Parameters.Item('version'), gen.version);
        end
        
        
        function verifyStimulusRegenerates(testCase, stim, dur)
            if nargin < 3
                dur = stim.Duration.Item2;
            end
            
            stimParams = dictionaryToStruct(stim.Parameters);
            stimData = getStimData(stim, dur);
            
            split = regexp(char(stim.StimulusID), '\.', 'split');
            construct = str2func(split{end});
            
            gen = construct(stimParams);
            regen = gen.generate();
            regenParams = dictionaryToStruct(regen.Parameters);
            regenData = getStimData(regen, dur);
            
            testCase.verifyEqual(regenParams, stimParams);
            testCase.verifyEqual(regenData, stimData);
            testCase.verifyTrue(regen.SampleRate.Equals(stim.SampleRate));
            testCase.verifyTrue(regen.Duration.Equals(stim.Duration));
            testCase.verifyTrue(strcmp(char(regen.Units), char(stim.Units)));
        end
        
    end
    
end


function p = makePulseParams()
    p.preTime = 50;
    p.stimTime = 430.2;
    p.tailTime = 70;
    p.amplitude = 100;
    p.mean = -60;
    p.sampleRate = 100;
    p.units = 'units';
end


function p = makeRampParams()
    p = makePulseParams();
end


function p = makeSineParams()
    p.preTime = 51.2;
    p.stimTime = 300;
    p.tailTime = 25;
    p.amplitude = 140;
    p.mean = -30;
    p.period = 100;
    p.phase = pi/2;
    p.sampleRate = 200;
    p.units = 'units';
end


function p = makeSquareParams()
    p = makeSineParams;
end


function p = makePulseTrainParams()
    p.preTime = 50;
    p.pulseTime = 100;
    p.intervalTime = 20;
    p.tailTime = 70;
    p.amplitude = 120;
    p.mean = -30;
    p.numPulses = 3;
    p.pulseTimeIncrement = 1;
    p.intervalTimeIncrement = 2;
    p.amplitudeIncrement = 3;
    p.sampleRate = 200;
    p.units = 'units';
end


function p = makeWaveformParams()
    p.waveshape = 0:0.2:100;
    p.sampleRate = 200;
    p.units = 'units';
end


function d = getStimData(stim, dur)
    if nargin == 1
        dur = stim.Duration.Item2;
    end

    block = NET.invokeGenericMethod('System.Linq.Enumerable', 'First', {'Symphony.Core.IOutputData'}, stim.DataBlocks(dur));
    d = double(Symphony.Core.Measurement.ToBaseUnitQuantityArray(block.Data));
end


function [pre, stim, tail] = getPts(params)
    pre = toPts(params.preTime, params.sampleRate);
    stim = toPts(params.stimTime, params.sampleRate);
    tail = toPts(params.tailTime, params.sampleRate);
end


function p = toPts(t, rate)
    p = round(t * 1e-3 * rate);
end