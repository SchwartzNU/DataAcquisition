classdef DAQOutputStream < Symphony.Core.IDAQOutputStream
    
    properties
        Device
        Configuration
        SampleRate
        MeasurementConversionTarget
        Clock
    end
    
    properties (SetAccess = private)
        HasMoreData
        Background
        Name
        CanSetSampleRate
        Active
        DAQ
    end
    
    properties (Access = private)
        LastDataPulled
    end
    
    methods
        
        function obj = DAQOutputStream(name, daq)            
            obj.Name = name;
            obj.DAQ = daq;
            
            obj.LastDataPulled = false;
        end
        
        
        function outData = PullOutputData(obj, duration)
            outData = obj.Device.PullOutputData(obj, duration);
            
            if outData.IsLast
                obj.LastDataPulled = true;
            end
        end
        
        
        function tf = get.HasMoreData(obj)
            tf = obj.Active && ~obj.LastDataPulled;
        end
        
        
        function tf = get.Active(obj)
            tf = ~isempty(obj.Device);
        end
        
        
        function tf = get.CanSetSampleRate(obj)
            tf = true;
        end
        
        
        function Reset(obj)
            obj.LastDataPulled = false;
        end
        
        function DidOutputData(obj, outputTime, duration, config)
            obj.Device.DidOutputData(obj, outputTime, duration, config);
        end
        
    end
    
end