classdef IClock < handle
    
    properties (Abstract, SetAccess = private)
        Now
    end
    
end