classdef CombinedStimulus < Symphony.Core.Stimulus
    
    properties (Access = private)
        Stimuli
        Combine
    end
        
    methods
        
        function obj = CombinedStimulus(stimulusID, parameters, stimuli, combine)
            stim = stimuli.Item(0);
            
            cParams = Symphony.Core.CombinedStimulus.CombineParameters(stimuli);
            enum = parameters.GetEnumerator();
            while enum.MoveNext()
                param = enum.Current;
                cParams.Add(param.Key, param.Value);
            end
            
            obj = obj@Symphony.Core.Stimulus(stimulusID, stim.Units, cParams);
            
            obj.Duration = stimuli.Item(0).Duration;
            obj.SampleRate = stimuli.Item(0).SampleRate;
            obj.Stimuli = stimuli;
            obj.Combine = combine;
        end
        
        
        function enumerable = DataBlocks(obj, blockDuration)
            enumerable = Enumerable(@GetEnumerator);
            
            function enum = GetEnumerator()
                enum = Enumerator(@MoveNext);
                
                enumerators = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                    {'Symphony.Core.IStimulus', 'System.Collections.Generic.IEnumerator'});
                
                for i = 1:obj.Stimuli.Count
                    stim = obj.Stimuli.Item(i-1);
                    enumerators.Add(stim, stim.DataBlocks(blockDuration).GetEnumerator());
                end
                
                enum.State.enumerators = enumerators;
                
                function tf = MoveNext()
                    enum.Current = [];
                    blocks = enum.State.enumerators;
                    
                    data = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                        {'Symphony.Core.IStimulus', 'Symphony.Core.IOutputData'});
                    
                    blockEnum = blocks.GetEnumerator();
                    while blockEnum.MoveNext()
                        block = blockEnum.Current;
                        
                        if ~block.Value.MoveNext()
                            tf = false;
                            return;
                        end
                        
                        data.Add(block.Key, block.Value.Current);
                    end
                    
                    enum.Current = obj.Combine(data);
                    enum.State.enumerators = blocks;
                    tf = true;
                end
            end
        end
        
    end
    
    methods (Static)
        
        function func = Add()
            func = @add;
            
            function out = add(data)
                import Symphony.Core.*;
                
                out = [];
                
                enum = data.GetEnumerator();
                while enum.MoveNext()
                    d = enum.Current.Value;
                    
                    if isempty(out)
                        out = d;
                    else
                        currentData = MeasurementList.ToBaseUnitQuantityArray(out.Data);
                        currentUnits = MeasurementList.HomogenousBaseUnits(out.Data);
                        
                        newData = MeasurementList.ToBaseUnitQuantityArray(d.Data);
                        newUnits = MeasurementList.HomogenousBaseUnits(d.Data);
                        
                        if length(currentData) ~= length(newData)
                            error('Stimuli ample rate mismatch?');
                        end
                        
                        if ~strcmp(currentUnits, newUnits)
                            error('Stimuli unit mismatch');
                        end
                        
                        combined = MeasurementList(currentData + newData, 0, currentUnits);
                        
                        out = OutputData(combined, out.SampleRate, out.IsLast || d.IsLast);
                    end
                end
            end
        end
        
        
        function parameters = CombineParameters(stimuli)
            parameters = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'System.String', 'System.Object'});
            
            for i = 0:stimuli.Count-1
                stim = stimuli.Item(i);
                
                prefix = ['stim' num2str(i) '_'];
                parameters.Add([prefix 'stimulusID'], stim.StimulusID);
                
                enum = stim.Parameters.GetEnumerator();
                while enum.MoveNext()
                    param = enum.Current;
                    parameters.Add([prefix param.Key], param.Value);
                end
            end
        end
        
    end
    
end