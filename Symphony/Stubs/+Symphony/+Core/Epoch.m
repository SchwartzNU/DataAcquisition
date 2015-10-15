classdef Epoch < handle
   
    properties        
        StartTime
        WaitForTrigger
        ShouldBePersisted
    end
    
    properties (SetAccess = private)
        ProtocolID 
        ProtocolParameters
        Stimuli
        Responses
        Backgrounds
        Keywords
        Duration
        IsComplete
        IsIndefinite
        Identifier % TODO: Remove identifier
    end
    
    methods
        
        function obj = Epoch(protocolID, parameters)            
            obj.ProtocolID = protocolID;
            if nargin == 2
                obj.ProtocolParameters = parameters;
            else
                obj.ProtocolParameters = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                    {'System.String', 'System.Object'});
            end
            obj.Stimuli = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IExternalDevice', 'Symphony.Core.IStimulus'});

            obj.Responses = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IExternalDevice', 'Symphony.Core.IResponse'});
            
            obj.Identifier = char(java.util.UUID.randomUUID());
            
            obj.Backgrounds = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IExternalDevice', 'Symphony.Core.EpochBackground'});
            
            obj.Keywords = System.Collections.ArrayList();
            obj.WaitForTrigger = false;
            obj.ShouldBePersisted = true;
        end
        
        
        function SetBackground(obj, device, background, sampleRate)
            obj.Backgrounds.Item(device, Symphony.Core.Background(background, sampleRate));
        end
        
        
        function d = get.Duration(obj)
            % TODO: Build out Maybe<TimeSpan> stuff?
            
            if obj.IsIndefinite
                d = Symphony.Core.TimeSpanOption.Indefinite;
                return;
            end
            
            dur = System.TimeSpan.Zero();
            
            for i = 0:obj.Stimuli.Values.Count-1
                if obj.Stimuli.Values.Item(i).Duration > dur
                    dur = obj.Stimuli.Values.Item(i).Duration;
                end
            end
            
            d = Symphony.Core.TimeSpanOption(dur);
        end
        
        
        function tf = get.IsComplete(obj)
            if obj.IsIndefinite
                tf = false;
                return;
            end
            
            for i = 0:obj.Stimuli.Values.Count-1
                if ~obj.Stimuli.Values.Item(i).IsComplete
                    tf = false;
                    return;
                end
            end
            
            for i = 0:obj.Responses.Values.Count-1
                if obj.Responses.Values.Item(i).Duration < obj.Duration
                    tf = false;
                    return;
                end
            end
            
            tf = true;
        end
        
        
        function tf = get.IsIndefinite(obj)
            tf = false;
            
            for i = 0:obj.Stimuli.Values.Count-1
                if obj.Stimuli.Values.Item(i).Duration == Symphony.Core.TimeSpanOption.Indefinite
                    tf = true;
                    break;
                end
            end
        end
        
    end
end