function waitForFileChange(dirname,fname)
%dirname
D = dir(dirname);
fnames = {D.name};
fileInd = strmatch(fname,fnames);
modDate = D(fileInd).datenum;
newDate = modDate;
while (newDate == modDate)
    D = dir(dirname);
    newDate = D(fileInd).datenum;    
end




