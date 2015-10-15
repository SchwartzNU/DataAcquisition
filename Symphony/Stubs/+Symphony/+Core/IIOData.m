classdef IIOData < handle
   
    properties (Abstract, SetAccess = private)
        Data                     % List
        SampleRate               % Measurement
        Duration
    end
    
end