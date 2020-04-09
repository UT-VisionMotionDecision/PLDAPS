function addToPathWithoutGit(dir, excludes, withSubdirs)
% function addToPathWithoutGit(dir, excludes, withSubdirs)
% 
% Add [dir] to Matlab path without including all the hidden versioning junk (.git, .svn)
% -- Optionally also exclude subdirs matching any entries in [excludes] string (or cell of strings)
% -- by default includes all subdirectories, set [withSubdirs] to false to only add the main [dir]
% 
    if nargin<3 || withSubdirs
        a = genpath(dir);
        withSubdirs = ' and subdirectories';
    else
        a = dir;
        withSubdirs = [];
    end
    
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
        disp([dir, withSubdirs, ' added to the path']);
    end
end
