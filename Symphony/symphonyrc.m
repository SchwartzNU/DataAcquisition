% These are the default configuration settings for Symphony. Do not modify this file directly.
%
% If you want to override some of the settings, create a symphonyrc function with the following format:
%
% function config = symphonyrc(config)
%
%     % Place all custom settings here...
%     % Follow the default symphonyrc file as a guide.
%
% end
%
% Save the function as symphonyrc.m in your MATLAB user path. You can find and set the location of your MATLAB user path 
% by using the userpath command in the MATLAB command window.

function config = symphonyrc(config)
    global DEMO_MODE;
    
    % Directory containing rig configurations.
    % Rig configuration .m files must be at the top level of this directory.
    config.rigConfigsDir = fullfile(fileparts(mfilename('fullpath')), 'SchwartzLab Rig Configurations');
    
    % Directory containing protocols.
    % Each protocol .m file must be contained within a directory of the same name as the protocol class itself.
    config.protocolsDir = fullfile(fileparts(mfilename('fullpath')), 'SchwartzLab Protocols');
    
    % Directory containing figure handlers (built-in figure handlers are always available).
    % Figure handler .m files must be at the top level of this directory.
    config.figureHandlersDir = '';
    
    % Text file specifying the source hierarchy.
    config.sourcesFile = fullfile(fileparts(mfilename('fullpath')), 'RetinaQuadrantHierarchy.txt');
    
    % Factories to define which DAQ controller and epoch persistor Symphony should use.
    % HekaDAQControllerFactory and EpochHDF5PersistorFactory are only supported on Windows.
    if ispc && ~DEMO_MODE
        config.daqControllerFactory = HekaDAQControllerFactory();
        config.epochPersistorFactory = EpochHDF5PersistorFactory();
    else
        config.daqControllerFactory = SimulationDAQControllerFactory('BlankSimulation');
        config.epochPersistorFactory = EpochXMLPersistorFactory();
    end
end