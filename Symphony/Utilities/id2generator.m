% Returns constructor function handle for a stimulus generator with the given id and version. This function assumes:
%   - The identifier ends with the generator's class name.
%   - Older versions of the generator exist on the MATLAB path with the suffix '_v[VERSION_NUMBER]', e.g. PulseGenerator_v1.

function constructor = id2generator(id, version)
    split = regexp(id, '\.', 'split');
    className = split{end};
    
    found = hasIdAndVersion(className, id, version);
    if ~found
        className = [className '_v' num2str(version)];
        found = hasIdAndVersion(className, id, version);
    end
    
    if found
        constructor = str2func(className);
    else
        constructor = [];
    end
end


function tf = hasIdAndVersion(className, id, version)
    hasId = false;
    hasVersion = false;

    mclass = meta.class.fromName(className);
    if isempty(mclass)
        tf = false;
        return;
    end

    plist = mclass.PropertyList;
    for i = 1:length(plist)
        if strcmp(plist(i).Name, 'identifier') && strcmp(plist(i).DefaultValue, id)
            hasId = true;
        end

        if strcmp(plist(i).Name, 'version') && (plist(i).DefaultValue == version)
            hasVersion = true;
        end
    end

    tf = hasId && hasVersion;
end