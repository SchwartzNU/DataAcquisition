function [] = mapLEDBackgroundsIntoList(epochList)
L = epochList.length;

for i=1:L   
    disp([num2str(i) ' of ' num2str(L)]);
    curEpoch = epochList.valueByIndex(i);
    commentStr = curEpoch.comment.toCharArray';
    
    searchStrList = {'Blue LED Mean', 'Green LED Mean', 'Red LED Mean'};
    for j=1:length(searchStrList)
        searchStr = searchStrList{j};        
        loc = strfind(commentStr,searchStr);
        [valPart, null] = strtok(commentStr(loc+length(searchStr)+3:end),';');
        val = str2double(valPart);
        searchStr = regexprep(searchStr, ' ', '_');
        %disp(['user:' searchStr ' = ' valPart]);
        curEpoch.protocolSettings.put(['user:' searchStr], val);
    end

end
