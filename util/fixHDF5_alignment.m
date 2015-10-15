function fixHDF5_alignment(fname)
tempVar = hdf5load(fname);

new_fname = [fname '_fixed'];
fnames = fieldnames(tempVar);

B_epochs = [];
normal_epochs = [];
for i=1:length(fnames) %for each epoch
    %i
    epochNumStr = fnames{i}(13:end); %skip 'params_epoch'
    if strcmp(epochNumStr(end),'B')
        B_epochs = [B_epochs str2num(epochNumStr(1:end-2))];
    else
        normal_epochs = [normal_epochs str2num(epochNumStr)];
    end
end

disp(['B_epochs = ' num2str(B_epochs)]);

fixedEpochs = [];
epochNums = input('Epoch numbers to fix (one block): ');
while ~isempty(epochNums)
    missingEpochs = [];
    for e=epochNums
        if isempty(strmatch(['params_epoch' num2str(e)], fnames))
            missingEpochs = [missingEpochs e];
        end
    end
    missingEpochs
    %    keyboard;
    
    offset = 0;
    for e=epochNums
        oldName = [];
        if ismember(e,missingEpochs)
            if ismember(e+1,B_epochs)
                oldName = ['params_epoch' num2str(e+1) '_B'];
                %else
                %   offset = offset-1
                %   disp(['epoch ' num2str(e) ' not found']);
            end
        elseif ismember(e,B_epochs)
            if ismember(e-1,missingEpochs)
                %do nothing, already fixed
            else
                e
                offset = offset+1
            end
        end
        newName = ['params_epoch' num2str(e)];
        if offset > 0 && ~ismember(e, B_epochs)
            if ismember(e-offset, B_epochs) %replace with B epoch
                oldName = ['params_epoch' num2str(e-offset) '_B'];
            else %replace with offset (previous?) epoch
                oldName = ['params_epoch' num2str(e-offset)];
            end
        else
            %don't change it
            if isempty(oldName)
                oldName = newName;
            end %otherwise it was set above
        end
        %fix it
        if isfield(tempVar,oldName)
            eval([newName '=tempVar.' oldName ';']);
            eval([newName '.epochNumber = ' num2str(e) ';']);
            fixedEpochs = [fixedEpochs e];
        else
            disp([oldName ' not found']);
        end
    end
    epochNums = input('Epoch numbers to fix (one block): ');
end

for i=1:length(fixedEpochs)
    curName = ['params_epoch' num2str(fixedEpochs(i))];
    hdf5append(new_fname,curName,curName);
end

non_fixed_epochs = setdiff(normal_epochs, fixedEpochs);
for i=1:length(non_fixed_epochs)
    curName = ['params_epoch' num2str(non_fixed_epochs(i))];
    eval([curName '=tempVar.' curName ';']);
    hdf5append(new_fname,curName,curName);
end


%     for e=epochNums
%         offset = length(find(B_epochs>epochNums(1) & B_epochs<e));
%         newName = ['params_epoch' num2str(e)];
%         if offset > 0 && ismember(e-offset, B_epochs)
%             oldName = ['params_epoch' num2str(e-offset) '_B'];
%         else
%             oldName = ['params_epoch' num2str(e-offset)];
%         end
% %        disp([newName '=tempVar.' oldName]);
%         if isfield(tempVar,oldName)
%             eval([newName '=tempVar.' oldName ';']);
%             eval([newName '.epochNumber = ' num2str(e) ';']);
%             fixedEpochs = [fixedEpochs e];
%         else
%             disp([oldName ' not found']);
%         end
%     end



%keyboard;

%    curBlockNumber = tempVar.params_epoch
%    ['fnames{' num2str(i) '}=tempVar_copy.(fnames{' num2str(i) '})' ]
%    eval([eval(['fnames{' num2str(i) '}])=tempVar_copy.(fnames{' num2str(i) '})' ]);
%    hdf5append(new_fname,['fnames{' num2str(i) '}'],['fnames{' num2str(i) '}']);
