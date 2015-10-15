classdef EpochHDF5PersistorFactory < EpochPersistorFactory

    methods
        
        function persistor = createPersistor(obj, path) %#ok<INUSL>
            persistor = Symphony.Core.EpochHDF5Persistor(path, '');
        end
        
    end
    
end

