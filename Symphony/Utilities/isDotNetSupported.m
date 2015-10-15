% Checks if .NET Framework is supported on the current system.

function tf = isDotNetSupported()
    tf = (verLessThan('matlab', '8.1.0') && ~isempty(which('NET.convertArray'))) ...
        || (~isempty(which('NET.isNETSupported')) && NET.isNETSupported);
end