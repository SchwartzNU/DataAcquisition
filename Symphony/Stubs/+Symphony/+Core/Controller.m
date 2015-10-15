classdef Controller < Symphony.Core.ITimelineProducer
   
    properties
        Clock
        DAQController
        BackgroundDataStreams
    end
    
    properties (SetAccess = private)
        Devices
        IsRunning
    end
    
    properties (Access = private)
        EpochQueue
        OutputDataStreams
        InputDataStreams
        
        IsPauseRequested
        IsStopRequested
        
        IncompleteEpochs
        Persistor
    end
    
    events
        ReceivedInputData
        CompletedEpoch
        DiscardedEpoch
    end
    
    methods      
        
        function obj = Controller()
            obj.Devices = System.Collections.ArrayList();
            
            obj.EpochQueue = System.Collections.Queue();
            obj.IncompleteEpochs = System.Collections.Queue();
            
            obj.OutputDataStreams = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IExternalDevice', 'Symphony.Core.SequenceOutputDataStream'});
            
            obj.InputDataStreams = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IExternalDevice', 'Symphony.Core.SequenceInputDataStream'});
            
            obj.BackgroundDataStreams = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IExternalDevice', 'Symphony.Core.IOutputDataStream'});
        end
        
        
        function controller = AddDevice(obj, device)
            obj.Devices.Add(device);
            device.Controller = obj;
            controller = obj;
        end
        
        
        function d = GetDevice(obj, deviceName)
            d = [];
            for i = 0:obj.Devices.Count-1
                device = obj.Devices.Item(i);
                if strcmp(device.Name, deviceName)
                    d = device;
                    break;
                end
            end
        end
        
        
        function outData = PullOutputData(obj, device, duration)
            outStream = obj.OutputDataStreams.Item(device);
            
            outData = [];
            
            while isempty(outData) || outData.Duration < duration
                if isempty(outData)
                    outData = outStream.PullOutputData(duration);
                else
                    outData = outData.Concat(outStream.PullOutputData(duration - outData.Duration));
                end
                
                obj.OutputPulled(device, outStream);
            end            
        end
        
        
        function OutputPulled(obj, device, stream)
            
            import Symphony.Core.*;
            
            if stream.IsAtEnd
                didBufferEpoch = false;
                
                if obj.EpochQueue.Count > 0
                    shouldBufferEpoch = ~obj.IsPauseRequested && ~obj.IsStopRequested;
                    
                    if shouldBufferEpoch
                        nextEpoch = obj.EpochQueue.Dequeue();

                        obj.BufferEpoch(nextEpoch);
                        obj.IncompleteEpochs.Enqueue(nextEpoch);
                        didBufferEpoch = true;
                    end
                end
                
                if ~didBufferEpoch
                    for i = 0:obj.OutputDataStreams.Count-1
                        device = obj.OutputDataStreams.Keys.Item(i);
                        sequenceOutStream = obj.OutputDataStreams.Values.Item(i);
                        
                        sequenceOutStream.Add(obj.BackgroundDataStreams.Item(device));
                    end

                    for i = 0:obj.InputDataStreams.Count-1
                        sequenceInStream = obj.InputDataStreams.Values.Item(i);

                        sequenceInStream.Add(NullInputDataStream());
                    end
                end
            end
        end
        
        
        function DidOutputData(obj, device, outputTime, timeSpan, config)
            obj.OutputDataStreams.Item(device).DidOutputData(outputTime, timeSpan, config);
        end
        
        
        function PushInputData(obj, device, inData)
            obj.OnReceivedInputData(device, inData);
            
            inStream = obj.InputDataStreams.Item(device);
            
            unpushedInData = inData;
            
            while unpushedInData.Duration > System.TimeSpan.Zero
                if inStream.Duration ~= Symphony.Core.TimeSpanOption.Indefinite
                    dur = inStream.Duration - inStream.Position;
                else
                    dur = unpushedInData.Duration;
                end
                
                [head,rest] = unpushedInData.SplitData(dur);
                
                inStream.PushInputData(head);
                unpushedInData = rest;
            
                obj.InputPushed(device, inStream);
            end
        end
        
        
        function InputPushed(obj, device, stream)
            
            if obj.IncompleteEpochs.Count == 0
                return
            end
            
            currentEpoch = obj.IncompleteEpochs.Peek();
            
            if currentEpoch.IsComplete  
                
                completedEpoch = obj.IncompleteEpochs.Dequeue();
                
                obj.OnCompletedEpoch(completedEpoch);
                
                if ~isempty(obj.Persistor) && completedEpoch.ShouldBePersisted
                    obj.Persistor.Serialize(completedEpoch);
                end
                
                if obj.IncompleteEpochs.Count == 0
                    obj.DAQController.RequestStop();
                end
            end
        end
        
        
        function OnReceivedInputData(obj, device, inData)
            notify(obj, 'ReceivedInputData', Symphony.Core.TimeStampedDeviceDataEventArgs(obj.Clock, device, inData));
        end
        
        
        function OnCompletedEpoch(obj, epoch)
            notify(obj, 'CompletedEpoch', Symphony.Core.TimeStampedEpochEventArgs(obj.Clock, epoch));
        end
        
        
        function OnDiscardedEpoch(obj, epoch)
            notify(obj, 'DiscardedEpoch', Symphony.Core.TimeStampedEpochEventArgs(obj.Clock, epoch));
        end
        
        
        function EnqueueEpoch(obj, epoch)
            obj.EpochQueue.Enqueue(epoch);
        end
        
        
        function ClearEpochQueue(obj)
            obj.EpochQueue.Clear();
        end
        
        
        function task = StartAsync(obj, persistor)
            obj.IsRunning = true;
            obj.IsPauseRequested = false;
            obj.IsStopRequested = false;
            
            task = System.Threading.Tasks.Task(@()obj.Process(obj.EpochQueue, persistor));
            task.Start();
        end
        
        
        function Process(obj, epochQueue, persistor)
            cleanup = onCleanup(@()obj.Stop());
            
            obj.ProcessLoop(epochQueue, persistor);
        end
        
        
        function Stop(obj)
            obj.IsRunning = false;
        end
        
        
        function ProcessLoop(obj, epochQueue, persistor)
            
            import Symphony.Core.*;
            
            if epochQueue.Count > 0
                cleanup = onCleanup(@()obj.ProcessLoopCleanup());
            
                epoch = epochQueue.Dequeue();
            
                obj.Persistor = persistor;

                for i = 0:obj.Devices.Count-1
                    device = obj.Devices.Item(i);

                    if device.OutputStreams.Count > 0
                        obj.OutputDataStreams.Add(device, SequenceOutputDataStream());
                    end

                    if device.InputStreams.Count > 0
                        obj.InputDataStreams.Add(device, SequenceInputDataStream());
                    end
                end

                obj.BufferEpoch(epoch);
                obj.IncompleteEpochs.Enqueue(epoch);

                obj.DAQController.Start(epoch.WaitForTrigger);
            end
        end
        
        
        function ProcessLoopCleanup(obj)
            obj.Persistor = [];
            
            obj.OutputDataStreams.Clear();
            obj.InputDataStreams.Clear();
                        
            while obj.IncompleteEpochs.Count > 0
                discardedEpoch = obj.IncompleteEpochs.Dequeue();
                obj.OnDiscardedEpoch(discardedEpoch);
            end
        end
           
                
        function BufferEpoch(obj, epoch)
            
            import Symphony.Core.*;
            
            epoch.StartTime = now;
            
            for i = 0:obj.OutputDataStreams.Count-1
                device = obj.OutputDataStreams.Keys.Item(i);
                sequenceOutStream = obj.OutputDataStreams.Values.Item(i);
                
                if epoch.Stimuli.ContainsKey(device)
                    outStream = StimulusOutputDataStream(epoch.Stimuli.Item(device), obj.DAQController.ProcessInterval);
                elseif epoch.Backgrounds.ContainsKey(device)
                    outStream = BackgroundOutputDataStream(epoch.Backgrounds.Item(device));
                else
                    error('Epoch is missing a stimulus/background');
                end
                
                sequenceOutStream.Add(outStream);
            end
            
            for i = 0:obj.InputDataStreams.Count-1
                device = obj.InputDataStreams.Keys.Item(i);
                sequenceInStream = obj.InputDataStreams.Values.Item(i);
                
                if epoch.Responses.ContainsKey(device)
                    inStream = ResponseInputDataStream(epoch.Responses.Item(device), epoch.Duration);
                else
                    inStream = NullInputDataStream(epoch.Duration);
                end
                
                sequenceInStream.Add(inStream);
            end
        end
        
        
        function WaitForCompletedEpochTasks(obj) %#ok<MANU>
            
        end
        
        
        function ExceptionalStop(obj, src, data) %#ok<INUSD>
            % MATLAB doesn't appear to appropriately bubble up exceptions on listeners
            
            %exception = addCause(MException('', 'DAQ Controller stopped'), data.Exception);
            %throw(exception);
        end
        
        
        function RequestPause(obj)
            obj.IsPauseRequested = true;
        end
        
        
        function RequestStop(obj)
            obj.IsStopRequested = true;
            obj.DAQController.RequestStop();
        end
        
        
        function persistor = BeginEpochGroup(obj, path, label, source)
            persistor = EpochXMLPersistor(path);
            
            keywords = NET.createArray('System.String', 0);
            properties = NET.createGeneric('System.Collections.Generic.Dictionary', {'System.String', 'System.Object'});
            identifier = System.Guid.NewGuid();
            startTime = obj.Clock.Now;
            persistor.BeginEpochGroup(label, source, keywords, properties, identifier, startTime);
        end
        
        
        function EndEpochGroup(~, persistor)
            persistor.EndEpochGroup();
            persistor.CloseDocument();
        end
        
        
        function t = GetType(obj)
            % Exists only to fool addNetListener.
            
            t.GetEvent = @(n)getEvent(n);
            
            function e = getEvent(name)
                e = [];
                evts = events(obj);
                
                if any(ismember(evts, name))
                    e = System.Reflection.EventInfo(name);
                end
            end
        end
        
    end
end