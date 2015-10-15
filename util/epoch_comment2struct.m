function params = epoch_comment2struct(comment)
  pairs = strsplit(';', comment);

  params = struct();
  for pair = pairs
    pair = pair{1};
    keyvalue = strsplit('=', pair);

    key = keyvalue(1);
    value = keyvalue(2);

    key = strrep(key, ' ', '');
    key = strrep(key, ':', '');

    value = strrep(value, ' ', '');
    value = str2num(char(value));

    params.(char(key)) = value;
  end
end

