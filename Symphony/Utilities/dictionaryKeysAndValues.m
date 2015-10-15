function [keys, values] = dictionaryKeysAndValues(d)
    keys = cell(1, d.Count);
    values = cell(1, d.Count);
    enum = d.Keys.GetEnumerator();
    i = 1;
    while enum.MoveNext()
        key = enum.Current();
        keys{i} = key;
        values{i} = d.Item(key);
        i = i + 1;
    end
end
