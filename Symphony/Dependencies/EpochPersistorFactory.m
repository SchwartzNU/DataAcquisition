classdef EpochPersistorFactory

    methods (Abstract)
        persistor = createPersistor(obj, path);
    end
    
end

