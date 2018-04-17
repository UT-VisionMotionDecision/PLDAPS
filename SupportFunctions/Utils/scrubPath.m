function scrubPath(excludes)

    a=path;
    b=textscan(a,'%s','delimiter',':');
    b=b{1};
    keepers = true(size(b));
    if ischar(excludes), excludes = {excludes}; end
    for i = 1:numel(excludes)
        keepers = keepers & cellfun(@isempty,strfind(b, excludes{i}));
    end
    
    b = setdiff(b, b(keepers));
    if numel(b)>0
        rmpath( b{:} )
    end
    fprintf('Directories containing keywords:\n\t[%s\b]\n\thave been removed from the path.\n', sprintf('''%s''\t',excludes{:}));
end