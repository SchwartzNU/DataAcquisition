classdef StimulusGenerator < handle
    
    properties (Constant, Abstract)
        identifier
        version
    end
    
    methods
        
        function obj = StimulusGenerator(params)
            
            classParams = obj.parameterNames();
            
            if isfield(params, 'version')
                if params.version ~= obj.version
                    error('Version mismatch');
                end
                params = rmfield(params, 'version');
            end
            
            if isfield(params, 'generatorClassName')
                % Only compare first n chars to allow version suffix (e.g. "MyGenerator_v3").
                if ~strncmp(params.generatorClassName, class(obj), length(params.generatorClassName))
                    error('Class name mismatch');
                end
                params = rmfield(params, 'generatorClassName');
            end
            
            fields = fieldnames(params);
            for i = 1:length(fields)
                field = fields{i};
                
                if ~any(strcmp(field, classParams))
                    error(['There is no parameter ''' field '''']);
                end
                
                obj.(field) = params.(field);
            end
        end
        
        
        function pn = parameterNames(obj)
            
            names = properties(obj);
            pn = {};
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                metaProp = findprop(obj, name);
                if ~metaProp.Hidden && ~metaProp.Constant
                    pn{end + 1} = name; %#ok<AGROW>
                end
            end
            pn = pn';
        end
        
        
        function p = parameters(obj)
            
            names = obj.parameterNames();
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                p.(name) = obj.(name);
            end
        end
        
        
        function p = stimulusParameters(obj)
            
            p = obj.parameters();
            p.version = obj.version;
            p.generatorClassName = class(obj);
            p = structToDictionary(p);
        end
        
        
        function [valid, msgs] = validate(obj)
            msgs = {};
            
            fields = fieldnames(obj.parameters);
            for i = 1:length(fields)
                field = fields{i};
                if isempty(obj.(field))
                    msgs{end + 1} = [field ' was not set'];
                end
            end
            
            valid = isempty(msgs);
        end
        
        
        function stim = generate(obj)
            [valid, errorMsgs] = obj.validate();
            if ~valid
                msg = ['Stimulus generator ''' obj.identifier ''' cannot generate a stimulus:'];
                for m = errorMsgs
                    msg = [msg '\n  - ' strrep(m{1},'\','\\')];
                end
                error('StimulusGenerator:FailedToGenerate', msg);
            end
            
            stim = obj.generateStimulus();
        end
        
    end
    
    
    methods (Abstract, Access = protected)
        
        stim = generateStimulus(obj);
        
    end
    
end