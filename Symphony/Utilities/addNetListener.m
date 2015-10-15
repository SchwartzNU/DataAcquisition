% This function is similar to the built-in addlistener function but it causes raised events to block until completion of 
% the callback. Listener callbacks added with addlistener do not block .NET and return immediately.

function listener = addNetListener(target, eventName, eventType, callback)
    event = target.GetType().GetEvent(eventName);
    listener = NET.createGeneric('System.EventHandler', {eventType}, callback);
    event.AddEventHandler(target, listener);
end