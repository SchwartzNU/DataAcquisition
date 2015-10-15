classdef EpochXMLPersistorFactory < EpochPersistorFactory

    methods
        
        function persistor = createPersistor(obj, path) %#ok<INUSL>
            persistor = Symphony.Core.EpochXMLPersistor(path);
        end
        
    end
    
end

