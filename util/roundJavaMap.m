function M = roundJavaMap(M,sigDigits)
keys = M.keySet;
iter = keys.iterator;

while(iter.hasNext)
    curKey = iter.next;
    if isempty(M.get(curKey))
        M.put(curKey, 'n');
    else
        M.put(curKey, sd_round(M.get(curKey),sigDigits));
    end
end



