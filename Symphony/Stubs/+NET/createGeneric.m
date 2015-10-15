function obj = createGeneric(className, paramTypes, varargin)
    if ~iscell(paramTypes)
        error('Parameters must be cell vector');
    end

    constructor = str2func(className);
    obj = constructor(paramTypes, varargin{:});
end