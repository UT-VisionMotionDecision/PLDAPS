function scrubPath(excludes)

excludes = {'PLDAPS','VPixx','Psychtoolbox','huklabBasics'};

    a=path;
    b=textscan(a,'%s','delimiter',':');
    b=b{1};
    keepers = true(size(b));
    if ischar(excludes), excludes = {excludes}; end
    for i = 1:numel(excludes)
        keepers = keepers & cellfun(@isempty,strfind(b, excludes{i}));
    end
    
    b = setdiff(b, b(keepers));
    rmpath( b{:} )
    fprintf('%s and subdirectories were scrubbed from the path\n', excludes{:});
end