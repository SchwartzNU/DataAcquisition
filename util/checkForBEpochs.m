function checkForBEpochs(fname)
info = hdf5info(fname);

L = length(info.GroupHierarchy.Groups);
B_epochs = [];

for i=1:L
    dataSetName = info.GroupHierarchy.Groups(i).Name;
    epochNumStr = dataSetName(14:end);
    if strcmp(epochNumStr(end),'B')
        B_epochs = [B_epochs str2num(epochNumStr(1:end-2))];        
    end
end

disp(['B_epochs = ' num2str(B_epochs)]);