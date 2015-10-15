% Returns a function handle for the named function at the given path (convenient for bypassing the MATLAB global path).

function handle = funcAtPath(functionName, path)

    file = fullfile(path, [functionName '.m']);
    if exist(file, 'file') ~= 2
        error([file ' does not exist']);
    end

    % Store breakpoints.
    tmp = dbstatus;
    tmpFile = tempname;
    save(tmpFile, 'tmp');
    
    currentDir = pwd;
    cd(path);
    handle = str2func(functionName);
    cd(currentDir);
    
    % Reload breakpoints.
    load(tmpFile);
    dbstop(tmp);
end

