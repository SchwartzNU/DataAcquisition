% This class can be configured in your symphonyrc function. Do not modify this file directly.

classdef SymphonyConfiguration < handle
    
    properties
        % Directory containing rig configurations.
        % Rig configuration .m files must be at the top level of this directory.
        rigConfigsDir
        
        % Directory containing protocols.
        % Each protocol .m file must be contained within a directory of the same name as the protocol class itself.
        protocolsDir
        
        % Directory containing figure handlers (built-in figure handlers are always available).
        % Figure handler .m files must be at the top level of this directory.
        figureHandlersDir
        
        % Text file specifying the source hierarchy.
        sourcesFile
        
        % Factory that defines the creation of the DAQController used by Symphony.
        daqControllerFactory
        
        % Factory that defines the creation of the EpochPersistor used by Symphony.
        epochPersistorFactory
        
        % A variable passed to all protocols and rig configurations.
        userData
    end
    
    
    methods
        
        function [valid, msgs] = validate(obj)
            msgs = {};
            
            if ~exist(obj.rigConfigsDir, 'dir')
                msgs{end + 1} = ['rigConfigsDir does not exist (' obj.rigConfigsDir ')'];
            end
            if ~exist(obj.protocolsDir, 'dir')
                msgs{end + 1} = ['protocolsDir does not exist (' obj.protocolsDir ')'];
            end
            if ~isempty(obj.figureHandlersDir) && ~exist(obj.figureHandlersDir, 'dir')
                msgs{end + 1} = ['figureHandlersDir does not exist (' obj.figureHandlersDir ')']; 
            end
            if ~exist(obj.sourcesFile, 'file')
                msgs{end + 1} = ['sourcesFile does not exist (' obj.sourcesFile ')'];
            end
            if ~isa(obj.daqControllerFactory, 'DAQControllerFactory')
                msgs{end + 1} = 'daqControllerFactory must be a sub-class of DAQControllerFactory';
            end
            if ~isa(obj.epochPersistorFactory, 'EpochPersistorFactory')
                msgs{end + 1} = 'epochPersistorFactory must be a sub-class of EpochPersistorFactory';
            end
            
            valid = isempty(msgs);
        end
        
    end
    
end

