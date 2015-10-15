classdef DAQControllerBase < Symphony.Core.IDAQController
   
    properties
        Clock
    end
    
    properties (SetAccess = protected)
        Running
        ProcessInterval
    end
    
    properties (SetAccess = private)
        Streams
        ActiveOutputStreams
        ActiveInputStreams
        ActiveOutputStreamsWithData
        InputStreams
        OutputStreams
        StopRequested
    end
    
    events
        ExceptionalStop
    end
    
    methods
        
        function obj = DAQControllerBase()
            obj.Running = false;
            obj.Streams = System.Collections.ArrayList();
        end
        
        
        function Start(obj, waitForTrigger)
            if ~obj.Running
                obj.Running = true;
                obj.StopRequested = false;
                
                obj.Process(waitForTrigger);
            end
        end
        
        
        function Process(obj, waitForTrigger)
            cleanup = onCleanup(@obj.Stop);
            try
                obj.ProcessLoop(waitForTrigger);
            catch x
                obj.StopWithException(x);
            end
        end
        
        
        function ProcessLoop(obj, waitForTrigger) %#ok<INUSD>
            
            iterationStart = clock;
            
            while obj.Running && ~obj.ShouldStop()
                outgoingData = obj.NextOutgoingData();
                
                outputTime = obj.Clock.Now;
                incomingData = obj.ProcessLoopIteration(outgoingData, [], []);

                obj.PushOutputDataEvents(outputTime, outgoingData);
                
                obj.PushIncomingData(incomingData);
                
                iterationDuration = [0 0 0 0 0 obj.ProcessInterval.TotalSeconds]; % date vector
                obj.SleepForRestOfIteration(iterationStart, iterationDuration);
                iterationStart = datevec(datenum(iterationStart + iterationDuration));
                
                % Need a small pause to allow MATLAB to catch up on events.
                pause(0.001);
            end
            
        end
        
        
        function outData = NextOutgoingData(obj)
            outData = NET.createGeneric('System.Collections.Generic.Dictionary', ...
                {'Symphony.Core.IDAQOutputStream', 'Symphony.Core.IOutputData'});
            
            activeStreams = obj.ActiveOutputStreams;
            for i = 0:activeStreams.Count-1
                stream = activeStreams.Item(i);
                outData.Add(stream, obj.NextOutputDataForStream(stream));
            end            
        end
             
        
        function outData = NextOutputDataForStream(obj, outStream)
            outData = outStream.PullOutputData(obj.ProcessInterval);
        end
        
        
        function PushOutputDataEvents(obj, outputTime, outgoingData)
            out = outgoingData.GetEnumerator();
            while out.MoveNext()
                kvp = out.Current;
                
                outputStream = kvp.Key;
                data = kvp.Value;

                outputStream.DidOutputData(outputTime, data.Duration, []);
            end
        end
        
        
        function PushIncomingData(~, incomingData)
            dataEnum = incomingData.GetEnumerator();
            while dataEnum.MoveNext()
                inStream = dataEnum.Current.Key;
                inStream.PushInputData(dataEnum.Current.Value);
            end
        end
        
        
        function SleepForRestOfIteration(~, iterationStart, iterationDuration)
            sleepEnd = datevec(datenum(iterationStart + iterationDuration));
            pause(etime(sleepEnd, clock));
        end
        
        
        function s = ShouldStop(obj)
            s = obj.ActiveOutputStreamsWithData.Count == 0 || obj.StopRequested;
        end
        
        
        function Stop(obj)
            obj.Running = false;
        end
        
        
        function StopWithException(obj, exception)
            obj.Running = false;
            obj.OnExceptionalStop(exception);
                           
            % Need to to rethrow this exception because MATLAB doesn't appropriately bubble up exceptions on events.
            rethrow(exception);
        end
        
        
        function OnExceptionalStop(obj, exception)
            notify(obj, 'ExceptionalStop', Symphony.Core.TimeStampedExceptionEventArgs(obj.Clock, exception));
        end
                      
        
        function RequestStop(obj)
            obj.StopRequested = true;
        end
        
        
        function SetStreamsBackground(~)
            
        end
        
        
        function s = get.ActiveOutputStreams(obj)
            s = System.Collections.ArrayList();
            
            outStreams = obj.OutputStreams;
            for i = 0:outStreams.Count-1
                if outStreams.Item(i).Active
                    s.Add(outStreams.Item(i));
                end
            end
        end
        
        
        function s = get.ActiveInputStreams(obj)
            s = System.Collections.ArrayList();
            
            inStreams = obj.InputStreams;
            for i = 0:inStreams.Count-1
                if inStreams.Item(i).Active
                    s.Add(inStreams.Item(i));
                end
            end
        end
        
        
        function s = get.ActiveOutputStreamsWithData(obj)
            s = System.Collections.ArrayList();
            
            outStreams = obj.ActiveOutputStreams;
            for i = 0:outStreams.Count-1
                if outStreams.Item(i).HasMoreData
                    s.Add(outStreams.Item(i));
                end
            end
        end
        
        
        function s = get.InputStreams(obj)
            s = System.Collections.ArrayList();
            
            for i = 0:obj.Streams.Count-1
                if isa(obj.Streams.Item(i), 'Symphony.Core.IDAQInputStream')
                    s.Add(obj.Streams.Item(i))
                end
            end
        end
        
        
        function s = get.OutputStreams(obj)
            s = System.Collections.ArrayList();
            
            for i = 0:obj.Streams.Count-1
                if isa(obj.Streams.Item(i), 'Symphony.Core.IDAQOutputStream')
                    s.Add(obj.Streams.Item(i))
                end
            end
        end
        
        
        function AddStream(obj, stream)
            obj.Streams.Add(stream);
        end
        
        
        function s = GetStream(obj, name)
            s = [];
            for i = 0:obj.Streams.Count-1
                if strcmp(name, obj.Streams.Item(i))
                    s = obj.Streams.Item(i);
                    return;
                end
            end
        end
        
    end
    
    methods (Abstract)
        incomingData = ProcessLoopIteration(obj, outputData, deficit, token);
    end
end