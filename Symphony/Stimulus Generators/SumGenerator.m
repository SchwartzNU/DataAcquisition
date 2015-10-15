% Generates a stimulus from the sum of a set of specified stimuli. All stimuli must have the same duration, units and
% sample rate.
% See details on the <a href="matlab:web('https://github.com/Symphony-DAS/Symphony/wiki/Standard-Stimulus-Generators#sumgenerator')">Symphony wiki</a>.

classdef SumGenerator < StimulusGenerator
    
    properties (Constant)
        identifier = 'io.github.symphony-das.SumGenerator'
        version = 1
    end
    
    properties
        stimuli     % Cell array of stimuli to sum
    end
    
    methods
        
        function obj = SumGenerator(params)
            if nargin == 0
                params = struct();
            end
            
            if ~isfield(params, 'stimuli')
                % Rebuild stimuli from given parameters.
                
                fields = fieldnames(params);
                
                stimuliParams = {};
                for i = 1:length(fields)
                    field = fields{i};
                    
                    if ~strcmp(field(1:4), 'stim')
                        continue;
                    end
                    
                    split = regexp(field, '_', 'split', 'once');
                    stimName = split{1};
                    stimParam = split{2};
                                        
                    stimNum = str2num(stimName(5:end));
                    if isempty(stimNum)
                        error('Error while parsing parameters struct');
                    end
                    
                    stimuliParams{stimNum + 1}.(stimParam) = params.(field);
                    params = rmfield(params, field);
                end
                
                params.stimuli = {};
                for i = 1:length(stimuliParams)
                    stimParams = stimuliParams{i};
                    
                    if ~isfield(stimParams, 'stimulusID')
                        error('Stimulus parameters is missing field ''stimulusID''');
                    end
                    id = stimParams.stimulusID;
                    stimParams = rmfield(stimParams, 'stimulusID');
                    
                    if ~isfield(stimParams, 'version')
                        error('Stimulus parameters is missing field ''version''');
                    end
                    ver = stimParams.version;
                    
                    constructor = id2generator(id, ver);
                    
                    if isempty(constructor)
                        error(['Unable to find generator with identifier and/or version: ' id ' ver.' num2str(ver)]);
                    end
                    
                    gen = constructor(stimParams);
                    params.stimuli{end + 1} = gen.generate();
                end
            end
            
            obj = obj@StimulusGenerator(params);
        end
        
        
        function p = stimulusParameters(obj)
            p = stimulusParameters@StimulusGenerator(obj);
            p.Remove('stimuli');
        end
        
    end
    
    methods (Access = protected)
        
        function stim = generateStimulus(obj)
            import Symphony.Core.*;
            
            stimList = NET.createGeneric('System.Collections.Generic.List', {'Symphony.Core.IStimulus'});
            for i = 1:length(obj.stimuli)
                stimList.Add(obj.stimuli{i});
            end
            
            stim = CombinedStimulus(obj.identifier, obj.stimulusParameters, stimList, CombinedStimulus.Add);
        end
        
    end
    
end