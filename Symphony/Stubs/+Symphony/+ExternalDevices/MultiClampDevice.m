classdef MultiClampDevice < Symphony.Core.ExternalDeviceBase
    
    properties (Access = private)
        Backgrounds
        Mode = 'VClamp'
    end
    
    methods
        
        function obj = MultiClampDevice(serialNumber, channel, clock, controller, modes, backgrounds) %#ok<INUSL>
            obj = obj@Symphony.Core.ExternalDeviceBase('', 'AutoMate', controller, backgrounds(1));
            
            obj.Backgrounds = containers.Map();
            for i = 1:numel(modes)
                obj.Backgrounds(char(modes(i))) = backgrounds(i);
            end
        end
        
        
        function outData = PullOutputData(obj, stream, duration) %#ok<INUSL>
            outData = obj.Controller.PullOutputData(obj, duration); 
        end
        
        
        function PushInputData(obj, stream, inData) %#ok<INUSL>
            obj.Controller.PushInputData(obj, inData);
        end
        
        
        function tf = HasDeviceOutputParameters(obj) %#ok<MANU>
            tf = true;
        end
        
        
        function tf = HasDeviceInputParameters(obj) %#ok<MANU>
            tf = true;
        end
        
        
        function params = DeviceParametersForInput(obj, ~)
            params.Data.OperatingMode = obj.Mode;
        end
        
        
        function params = DeviceParametersForOutput(obj, ~)
            params.Data.OperatingMode = obj.Mode;
        end
        
        
        function params = CurrentDeviceInputParameters(obj)
            params.Data.OperatingMode = obj.Mode;
        end
        
        
        function params = CurrentDeviceOutputParameters(obj)
            params.Data.OperatingMode = obj.Mode;
        end
        
        
        function SetBackgroundForMode(obj, mode, background)
            import Symphony.ExternalDevices.*
            
            switch mode
                case OperatingMode.VClamp
                    mode = 'VClamp';
                case OperatingMode.IClamp
                    mode = 'IClamp';
                case OperatingMode.IO
                    mode = 'IO';
            end
            
            obj.Backgrounds(mode) = background;            
        end
        
        
        function b = Background(obj)
            b = obj.Backgrounds(obj.Mode);
        end
        
        
        function Dispose(obj) %#ok<MANU>
            
        end
        
    end
end