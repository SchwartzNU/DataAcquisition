classdef HekaDAQControllerFactory < DAQControllerFactory
    
    methods
        
        function daq = createDAQ(obj) %#ok<MANU>

            % Add required assembly
            try
                addSymphonyAssembly('HekaDAQInterface');
            catch %#ok<CTCH>
                error('Unable to load the Heka DAQ Interface. You probably need to install the Heka ITC drivers.');
            end
            
            import Symphony.Core.*;
            
            % Can't seem to import a namespace in the same function where the assembly is loaded?
            %import Heka.*;
                
            % Register the unit converters
            Heka.HekaDAQInputStream.RegisterConverters();
            Heka.HekaDAQOutputStream.RegisterConverters();

            % Get the bus ID of the Heka ITC.
            % (Stored as a local pref so that each rig can have its own value.)
            hekaID = getpref('Symphony', 'HekaBusID', '');
            if isempty(hekaID)
                answer = questdlg('How is the Heka connected?', 'Symphony', 'USB', 'PCI', 'Cancel', 'Cancel');
                if strcmp(answer, 'Cancel')
                    error('Symphony:Heka:NoBusID', 'Cannot create a Heka controller without a bus ID');
                elseif strcmp(answer, 'PCI')
                    % Convert these to Matlab doubles because they're more flexible calling .NET functions in the future
                    hekaID = double(Heka.NativeInterop.ITCMM.ITC18_ID);
                else    % USB
                    hekaID = double(Heka.NativeInterop.ITCMM.USB18_ID);
                end
                setpref('Symphony', 'HekaBusID', hekaID);
            end

            daq = Heka.HekaDAQController(hekaID, 0);
            daq.InitHardware();
        end
        
    end
    
end

