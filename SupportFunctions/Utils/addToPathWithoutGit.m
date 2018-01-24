function addToPathWithoutGit(dir, excludes)
    a=genpath(dir);
    if isempty(a)
        fprintf('%s not found...attempting to continue\n', dir);
    else
        b=textscan(a,'%s','delimiter',':');
        b=b{1};
        b(~cellfun(@isempty,strfind(b,'.git')))=[];
        b(~cellfun(@isempty,strfind(b,'.svn')))=[];
        if nargin>1
            if ~iscell(excludes), excludes = {excludes}; end
            for i = 1:numel(excludes)
                if ~isempty(excludes{i})
                    b(~cellfun(@isempty,strfind(b, excludes{i})))=[];
                end
            end
        end
        addpath(b{:})
        disp([dir ' and subdirectories added to the path']);
    end
end