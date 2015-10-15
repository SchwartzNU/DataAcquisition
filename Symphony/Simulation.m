% Create a sub-class of this class to define a simulation of an experimental subject for testing purposes.
% See Simulations/LoopbackSimulation for example.

classdef Simulation < handle
    
    properties
        daqController
    end
        
    methods (Abstract)
        % This method should implement the simulation algorithm. When the SimulationDAQController "outputs" a portion of 
        % stimuli, this method will be called to request the simulated input to return. 
        %
        % The DAQController outputs stimuli in small time steps, meaning this method is likely called multiple times per
        % epoch. The duration of the current time step is available through timeStep.
        input = runner(obj, output, timeStep);
    end
    
end

