classdef SimulationDAQControllerFactory < DAQControllerFactory
    
    properties
        simulation
    end
    
    methods
        
        function obj = SimulationDAQControllerFactory(simulation)
            obj.simulation = simulation;
        end
        
        
        function daq = createDAQ(obj)
            
            addSymphonyAssembly('Symphony.SimulationDAQController');
  
            import Symphony.Core.*;
            
            % Can't seem to import a namespace in the same function where the assembly is loaded?
            %import Symphony.SimulationDAQController.*;
            
            Converters.Register(Measurement.UNITLESS, 'V', @(m) m);
            
            daq = Symphony.SimulationDAQController.SimulationDAQController();
            
            constructor = str2func(obj.simulation);
            sim = constructor();
            sim.daqController = daq;
            
            daq.SimulationRunner = @(input,timeStep)sim.runner(input, timeStep);
        end
            
    end
    
end

