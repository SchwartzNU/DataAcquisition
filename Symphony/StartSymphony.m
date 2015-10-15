% Starts the Symphony application.

function StartSymphony()

    if verLessThan('matlab', '8.0')
        error('Symphony requires MATLAB 8.0 (R2012b) or later');
    end

    % Add base directories to the path.
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    addpath(fullfile(parentDir, 'Dependencies'));
    addpath(fullfile(parentDir, 'Simulations'));
    addpath(fullfile(parentDir, 'Stimulus Generators'));
    addpath(fullfile(parentDir, 'Utilities'));
    
    % Use .NET framework stubs if .NET is not supported.
    if ~isDotNetSupported()
        addpath(fullfile(parentDir, 'Stubs'));
    end

    % Load the Symphony framework.
    addSymphonyAssembly('Symphony.Core');
    addSymphonyAssembly('Symphony.ExternalDevices');        

    % Declare or retrieve the current Symphony instance.
    persistent symphonyInstance;

    if isempty(symphonyInstance) || ~isvalid(symphonyInstance)
        config = SymphonyConfiguration();
        
        % Run the built-in configuration function.
        config = symphonyrc(config);

        % Run the user-specific configuration function.
%         up = userpath;
%         up = regexprep(up, '[;:]$', ''); % Remove semicolon/colon at end of user path
%         if exist(fullfile(up, 'symphonyrc.m'), 'file')
%             rc = funcAtPath('symphonyrc', up);
%             config = rc(config);
%         end

        % Create the Symphony instance
        symphonyInstance = SymphonyUI(config);
    else
        symphonyInstance.showMainWindow();
    end
end