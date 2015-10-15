classdef ExternalDeviceBase < Symphony.Core.IExternalDevice
   
    properties
        Controller
        Background
        Clock
        Name
        Manufacturer
        InputSampleRate
        OutputSampleRate
    end
    
    properties (SetAccess = private)
        Streams
        InputStreams
        OutputStreams
    end
    
    methods
        
        function obj = ExternalDeviceBase(name, manufacturer, controller, background)
            obj.Name = name;
            obj.Manufacturer = manufacturer;
            obj.Controller = controller;
            obj.Background = background;
            
            obj.Streams = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'System.String', 'Symphony.Core.IDAQStream'});
            
            obj.Controller.AddDevice(obj);
        end
        
        
        function s = get.InputStreams(obj)
            s = System.Collections.ArrayList();
            
            for i = 0:obj.Streams.Count-1
                if isa(obj.Streams.Values.Item(i), 'Symphony.Core.IDAQInputStream')
                    s.Add(obj.Streams.Values.Item(i))
                end
            end
        end
                
                
        function s = get.OutputStreams(obj)
            s = System.Collections.ArrayList();
            
            for i = 0:obj.Streams.Count-1
                if isa(obj.Streams.Values.Item(i), 'Symphony.Core.IDAQOutputStream')
                    s.Add(obj.Streams.Values.Item(i))
                end
            end
        end
        
        
        function device = BindStream(obj, arg1, arg2)            
            if nargin == 2
                stream = arg1;
                obj.Streams.Add(stream.Name, stream);
            else
                stream = arg2;
                obj.Streams.Add(arg1, stream);
            end    
            
            if isa(stream, 'Symphony.Core.IDAQOutputStream')
                stream.Device = obj;
            else
                stream.Devices.Add(obj);
            end
            
            device = obj;
        end
        
        
        function ApplyBackground(obj) %#ok<MANU>
        
        end
        
        
        function DidOutputData(obj, stream, outputTime, timeSpan, config)
            obj.Controller.DidOutputData(obj, outputTime, timeSpan, config);
        end
        
    end
end