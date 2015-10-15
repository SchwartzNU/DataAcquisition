classdef DAQControllerFactory
    
    methods (Abstract)
        daq = createDAQ(obj);
    end
    
end

