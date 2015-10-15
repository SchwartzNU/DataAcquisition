function [] = addGammaTablesNew(tree,rigLetters,dateRange,tables)

cellNodes = getLevel(tree,'protocolSettings.acquirino:cellBasename'); %checks for isSelected
L = length(rigLetters);

for i=1:length(cellNodes)
    curName = cellNodes(i).splitValue;
    s = strtok(curName,'c');
    datePart = s(1:6);
    dnum = datenum(['20' datePart(5:6) '/' datePart(1:2) '/' datePart(3:4)],26);
    rigLettter = s(7);    
    results = struct;
    match = 0;
    for j=1:L
       if strcmp(rigLettter,rigLetters{j}) && dnum >= dateRange{j}(1) && dnum <= dateRange{j}(2) %match
           match = 1;
           results.gamma = tables{j};
           cellNodes(i).custom.put('results',riekesuite.util.toJavaMap(results));
       end
    end
    if match == 0
        warning([s ': gamma table match not found']);
    end
end
