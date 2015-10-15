function v = isCompoundField(s, compound_fname)

fieldnames = {};

[field_token, rest] = strtok(compound_fname,'.');

fieldnames{1} = field_token;
i = 2;
while ~isempty(rest)
    [field_token, rest] = strtok(rest,'.');
    fieldnames{i} = field_token;
    i=i+1;
end

curObj = s;
for i=1:length(fieldnames)
    if isstruct(curObj)
        if ~isfield(curObj,fieldnames{i})
            v = 0;
            return;
        end
    else
        if ~curObj.findprop(fieldnames{i}).isvalid
            v = 0;
            return;
        end
    end
    curObj = curObj.(fieldnames{i});
end
v=1;