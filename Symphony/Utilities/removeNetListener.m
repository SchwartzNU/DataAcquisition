function removeNetListener(target, eventName, listener)
    event = target.GetType().GetEvent(eventName);
    event.RemoveEventHandler(target, listener);
    
    % We need to force .NET garbage collection or MATLAB's GC will not be able to collect the callback (locking class
    % definitions and causing a possible memory leak).
    delete(listener);
    System.GC.Collect();
end