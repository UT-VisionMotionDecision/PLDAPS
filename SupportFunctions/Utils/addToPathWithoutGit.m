function addToPathWithoutGit(dir)
    a=genpath(dir);
    b=textscan(a,'%s','delimiter',':');
    b=b{1};
    b(~cellfun(@isempty,strfind(b,'.git')))=[];
    b(~cellfun(@isempty,strfind(b,'.svn')))=[];
    addpath(b{:})
    disp([dir ' and subdirectories added to the path']);
end