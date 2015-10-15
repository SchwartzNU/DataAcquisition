function hrn = humanReadableParameterName(n)
    hrn = regexprep(n, '([A-Z][a-z]+)', ' $1');
    hrn = regexprep(hrn, '([A-Z][A-Z]+)', ' $1');
    hrn = regexprep(hrn, '([^A-Za-z ]+)', ' $1');
    hrn = strtrim(hrn);
    
    % TODO: improve underscore handling, this really only works with lowercase underscored variables
    hrn = strrep(hrn, '_', '');
    
    hrn(1) = upper(hrn(1));
end
