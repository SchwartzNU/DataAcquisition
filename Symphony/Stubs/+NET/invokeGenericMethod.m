function varargout = invokeGenericMethod(obj, methodName, paramTypes, varargin) %#ok<INUSL>
    method = str2func([obj '.' methodName]);
    varargout{:} = method(varargin{:});
end

