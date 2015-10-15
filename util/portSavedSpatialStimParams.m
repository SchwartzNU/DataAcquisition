function portSavedSpatialStimParams()

curDir = pwd;

cd('~/acquisition/SpatialStimParams/');
D = dir(pwd);

for i=1:length(D)
    curName = D(i).name;
    if ~strcmp(curName(1),'.') && strcmp(curName(end-2:end),'.h5')
        disp(curName);
        temp = hdf5load(curName);
        oldParams = temp.params;
        oldParamNames = fieldnames(oldParams);
        stimClass = oldParams.stimClass;
        newParamNames = properties(stimClass);

        L = length(newParamNames);
        missingParams = 0;
        params = oldParams;
        for p=1:L
           if isempty(strmatch(newParamNames{p}, oldParamNames))
               missingParams = missingParams+1;
               params.(newParamNames{p}) = 0;
               disp(['Parameter ''''' newParamNames{p}  ''''' added'])
           end            
        end
        if missingParams == 0
            disp('params match'); 
        else
            %keyboard;
            delete(curName);
            if isfield(params, 'executableString')
                params.executableString = params.executableString.toChar; %for some reason this needs to be done so hdf5file saves correctly
            end
            hdf5save(curName,'params','params');
        end
    end
end

cd(curDir);
