classdef RigA_TwoAmps < RigConfiguration
    
    properties (Constant)
        displayName = 'Rig A - Two Amps'
        micronsPerPixel = 1.38; %eventually add this to device object
        frameTrackerPosition = [160, 120];
        filterWheelComPort = 'COM8'
        filterWheelNDFs = [2, 4, 5, 6, 7, 8];
        NDFattenuation = [0.0105, 8.0057e-05, 6.5631e-06, 5.5485e-07, 5.5485e-08, 5.5485e-09];
        fitBlue = [3.1690e-12, -2.2180e-09, 7.3530e-07, 1.0620e-05];
        fitGreen =[1.9510e-12, -1.4200e-09, 5.1430e-07, 9.6550e-06];
    end
    
    methods      
        
        function createDevices(obj)     
            % Add a multiclamp device named 'Amplifier_Ch1'.
            % Multiclamp Channel = 1
            % ITC Output Channel = DAC Output 0 (ANALOG_OUT.0)
            % ITC Input Channel = ADC Input 0 (ANALOG_IN.0)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0'); 
            obj.addMultiClampDevice('Amplifier_Ch2', 2, 'ANALOG_OUT.1', 'ANALOG_IN.1'); 
            
            % Add a device named 'Red_LED'.
            % ITC Output Channel = DAC Output 1 (ANALOG_OUT.1)
            % ITC Input Channel = None
            %obj.addDevice('Red_LED', 'ANALOG_OUT.1', '');
            
            % Add a device named 'Green_LED'.
            % ITC Output Channel = DAC Output 2 (ANALOG_OUT.2)
            % ITC Input Channel = None
            %obj.addDevice('Green_LED', 'ANALOG_OUT.2', '');
            
            % Add a device named 'BathTemp'.
            % ITC Output Channel = None
            % ITC Input Channel = ADC Input 7 (ANALOG_IN.7)
            obj.addDevice('BathTemp', '', 'ANALOG_IN.7');
            
            %Add Stage device for visual stim
            %obj.addStageDevice('Projector_Con'); %through condenser
            
            %Add two input channels for frameTriggers (from LightCrafter)
            %in digital INs
            obj.addDevice('FrameTrigger', '', 'DIGITAL_IN.0');
            obj.addDevice('PatternTrigger', '', 'DIGITAL_IN.1');
            
            % Add a device named 'Oscilliscope_Trig'.
            % ITC Output Channel = TTL Output 0 (DIGITAL_OUT.0)
            % ITC Input Channel = None
            obj.addDevice('Oscilloscope_Trigger', 'DIGITAL_OUT.0', '');
        end
        
    end
end
