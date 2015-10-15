function s = dictionaryToStruct(d)
    s = {};
    
    keys = {};
    dictKeys = d.Keys.GetEnumerator();
    while dictKeys.MoveNext()
        keys{end + 1} = char(dictKeys.Current()); %#ok<AGROW>
    end
    
    for key = keys
        value = d.Item(key{1});
        if isa(value, 'System.String')
            value = char(value);
        end
        s.(key{1}) = value;
    end
end
