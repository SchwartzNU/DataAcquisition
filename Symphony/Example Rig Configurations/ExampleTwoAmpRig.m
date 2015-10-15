classdef ExampleTwoAmpRig < RigConfiguration
    
    properties (Constant)
        displayName = 'Example Two Amp Rig'
    end
    
    methods      
        
        function createDevices(obj)     
            % Add a multiclamp device named 'Amplifier_Ch1'.
            % Multiclamp Channel = 1
            % ITC Output Channel = DAC Output 0 (ANALOG_OUT.0)
            % ITC Input Channel = ADC Input 0 (ANALOG_IN.0)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0'); 
            
            % Add a multiclamp device named 'Amplifier_Ch2'.
            % Multiclamp Channel = 2
            % ITC Output Channel = DAC Output 1 (ANALOG_OUT.1)
            % ITC Input Channel = ADC Input 1 (ANALOG_IN.1)
            obj.addMultiClampDevice('Amplifier_Ch2', 2, 'ANALOG_OUT.1', 'ANALOG_IN.1');
            
            % Add a device named 'Red_LED'.
            % ITC Output Channel = DAC Output 1 (ANALOG_OUT.1)
            % ITC Input Channel = None
            obj.addDevice('Red_LED', 'ANALOG_OUT.2', '');
            
            % Add a device named 'Green_LED'.
            % ITC Output Channel = DAC Output 2 (ANALOG_OUT.2)
            % ITC Input Channel = None
            obj.addDevice('Green_LED', 'ANALOG_OUT.3', '');
            
            % Add a device named 'Oscilliscope_Trig'.
            % ITC Output Channel = TTL Output 0 (DIGITAL_OUT.0)
            % ITC Input Channel = None
            obj.addDevice('Oscilloscope_Trigger', 'DIGITAL_OUT.0', '');
        end
        
    end
end
