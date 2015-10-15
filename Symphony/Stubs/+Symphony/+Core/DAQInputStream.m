classdef DAQInputStream < Symphony.Core.IDAQInputStream
   
    properties
        Configuration
        SampleRate
        MeasurementConversionTarget
        Clock
    end
    
    properties (SetAccess = private)
        Name
        CanSetSampleRate
        Active
        Devices
        DAQ
    end
    
    methods
        
        function obj = DAQInputStream(name, daq)            
            obj.Devices = System.Collections.ArrayList();
            obj.Name = name;
            obj.DAQ = daq;
        end
        
        
        function tf = get.Active(obj)
            tf = obj.Devices.Count > 0;
        end
        
        
        function tf = get.CanSetSampleRate(obj)
            tf = true;
        end            
        
        
        function PushInputData(obj, inData)
            for i = 0:obj.Devices.Count-1
                device = obj.Devices.Item(i);
                device.PushInputData(obj, inData);
            end
        end
        
    end
end