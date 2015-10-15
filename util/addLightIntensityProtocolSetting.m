function epochList = addLightIntensityProtocolSetting(epochList, voltage_param, default_ndf, default_switch, conversionTable)
%Rstar = splitOnLightIntensity(epoch, stimName, voltage_param, default_ndf,default_switch, conversionTable)

%get cell date (experiment date)
%for now, I am just getting the first 6 numbers - this assumes 2 digits for
%month/day/year


for i=1:epochList.length
    epoch = epochList.valueByIndex(i);
    
    cellName = epoch.protocolSettings.('acquirino:cellBasename');
    cellDate = cellName(1:6);
    
    if ~strcmp(voltage_param,'BlueBackground') %hack until this is mapped correctly
        
        %get stimulus
        stim = epoch.stimuli;
        stimNames = fieldnames(stim);
        if isempty(stimNames)
            disp('No stimulus found for this epoch');
            Rstar = 'null';
            return;
        elseif length(stimNames) > 1
            error(['Multiple stimuli for this epoch: ' stimNames]);
        else
            stimName = stimNames{1};
        end
        
        %get switch
        switchKeywordInd = strmatch('switch',epoch.keywords.elements);
        if length(switchKeywordInd)==1
            [null, level] = strtok(epoch.keywords.elements{switchKeywordInd},'=');
            switchVal = str2double(level(2:end));
        else
            switchVal = default_switch;
        end
        
        %get ndf
        ndfKeywordInd = strmatch('ndf',epoch.keywords.elements);
        if length(ndfKeywordInd)==1
            [null, level] = strtok(epoch.keywords.elements{ndfKeywordInd},'=');
            ndfVal = str2double(level(2:end));
        else
            ndfVal = default_ndf;
        end
        
    end
    
    %get voltage
    if strcmp(voltage_param,'BlueBackground') %hack until this is mapped correctly
        stimName = 'Blue_LED';
        switchVal = default_switch;
        
        %get ndf
        ndfKeywordInd = strmatch('ndf',epoch.keywords.elements);
        if length(ndfKeywordInd)==1
            [null, level] = strtok(epoch.keywords.elements{ndfKeywordInd},'=');
            ndfVal = str2double(level(2:end));
        else
            ndfVal = default_ndf;
        end
        
        searchStr = 'Blue LED Mean =';
        pos = strfind(epoch.comment,searchStr);
        V = str2num(epoch.comment(pos+length(searchStr):end));
    else
        try
            V = epoch.protocolSettings.(voltage_param);
        catch
            error(['Parameter ' voltage_param ' not found']);
        end
    end
    
    %assemble search field name
    searchField = [stimName ':ndf' num2str(ndfVal) ':switch' num2str(switchVal)];
    
    expMap = conversionTable(cellDate);
    try
        factor = expMap(searchField);
    catch
        error(['Cell Date: ' cellDate ' ' searchField ' not found']);
    end
    
    %do the conversion
    Rstar = V*factor;
    %could add a part to truncate to a certain precision here
    
    if strcmp(voltage_param,'BlueBackground') %hack until this is mapped correctly
        epoch.setProtocolSetting('user:Background_Rstar', Rstar);
    else
        epoch.setProtocolSetting('user:Rstar', Rstar);
    end
    
end
