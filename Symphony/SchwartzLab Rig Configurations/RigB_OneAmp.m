classdef RigB_OneAmp < RigConfiguration
    
    properties (Constant)
        displayName = 'Rig B - One Amp'
        micronsPerPixel = 2.3; %eventually add this to device object
        frameTrackerPosition = [110, 225];
        filterWheelComPort = 'COM12'
        filterWheelNDFs = [0, 2, 3, 4, 5, 6];
        NDFattenuation = [1.0, 0.0076, 6.23E-4, 6.93E-5, 8.32E-6, 1.0E-6]; 
        fitBlue = [1.0791E-11 -6.3562E-09 1.8909E-06 2.8196E-05];
        fitGreen =[4.432E-12, -3.514E-9, 1.315E-6, 1.345E-5];
        %PREVIOUS fitBlue = [7.603E-12, -6.603E-9, 2.133E-6, 3.398E-5];
        greenLED_coeffs = [-0.002081, 0.01692, -0.07819, 0.4261, -0.005983];
        uvLED_coeffs = [.005939, -0.0784, 0.282, -0.0005324, 0.01025];   
        LED_area = 1.5323e+05 %square microns: diameter = 441.7 um
        calib_GREEN = 0.0548 %uW at value of 0.1 
        calib_UV = 0.1747 %uW at value of 0.1 
        %preFactors for calibration
        green_Scone = 1.5694e+15;
        green_Mcone = 6.1707e+18;
        green_Rod = 4.8011e+18;
        uv_Scone = 3.7692e+18;
        uv_Mcone = 1.2463e+18;
        uv_Rod = 7.7704e+17;
        
    end
    
    properties 
       gamma_X = [];
       greenLED_gamma = [];
       uvLED_gamma = [];
    end
    
    
    methods      
        
        function createDevices(obj)     
            % Add a multiclamp device named 'Amplifier_Ch1'.
            % Multiclamp Channel = 1
            % ITC Output Channel = DAC Output 0 (ANALOG_OUT.0)
            % ITC Input Channel = ADC Input 0 (ANALOG_IN.0)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0'); 
            
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
            
            %scanhead trigger
            obj.addDevice('Scanhead_Trigger', 'DIGITAL_OUT.1', '');
            
            %optogenetics LED trigger
            %obj.addDevice('Optogenetics_LED', 'DIGITAL_OUT.2', '');
            
            %optogenetics LED current
            %obj.addDevice('Optogenetics_LED_current', 'ANALOG_OUT.2', '');
            
            %LEDs 
            obj.addDevice('UV_LED', 'ANALOG_OUT.2', '');
            obj.addDevice('GREEN_LED', 'ANALOG_OUT.3', '');
            
            %compute gamma tables
            voltages = [0:.01:5];
            obj.greenLED_gamma = polyval(obj.greenLED_coeffs, voltages);
            obj.uvLED_gamma = polyval(obj.uvLED_coeffs, voltages);
            obj.gamma_X = voltages;
                        
        end
        
    end
end
