% Describes protocol class parameters (properties in a protocol class).
%
% ProtocolParameter objects are obtained from the parameterProperty method of a protocol.

classdef ParameterProperty < handle
    
    properties (SetAccess = private)
        meta
    end
    
    properties
        % Overrides any default value defined in the properties block of the protocol.
        defaultValue
        
        % Displays as a tooltip when hovering over the parameter in the edit parameters window.
        description = ''
        
        % Displays alongside the parameter in the edit parameters window.
        units = ''
        
        % Tab in the GUI in which this parameter should be displayed
        displayTab = 'protocol'        
    end
    
    methods
        
        function obj = ParameterProperty(metaProperty)
            if ~isa(metaProperty, 'meta.property')
                error('metaProperty must be of class meta.property');
            end
            
            obj = obj@handle();
            obj.meta = metaProperty;
        end
        
        
        function set.defaultValue(obj, value)
            if obj.meta.Dependent
                error('Cannot define the default value of a dependent parameter');
            end
            obj.defaultValue = value;
        end
        
        
        function value = get.defaultValue(obj)          
            value = [];
            if ~isempty(obj.defaultValue)
                value = obj.defaultValue;
            elseif obj.meta.HasDefault
                value = obj.meta.DefaultValue;
            end
        end
        
        
        function set.description(obj, value)
            if ~ischar(value)
                error('description must be of class char');
            end
            obj.description = value;
        end
        
    end
    
end

