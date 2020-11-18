function loadPLDAPS()
%loadPLDAPS   load the pldaps folders from  into the matlab path

% Set unified location for Matlab toolboxes
toolRoot = fullfile('~','MLtoolbox');


%% Setup the path
% remove other/conflicting copies from path
scrubPath({'PLDAPS','VPixx','Psychtoolbox'});

% PLDAPS stuff (with additional excludes)
addToPathWithoutGit( fullfile(toolRoot, 'Psychtoolbox'));   %, {'Octave','R2007a','EyelinkDemos'});
addToPathWithoutGit( fullfile(toolRoot, 'PLDAPS'), '/PLDAPS/doc');

% Place OS-dependent copy of datapixx.mex AHEAD of PTB version (shadowing it)
if ismac
    osStr = 'macosx64';
elseif isunix
    osStr = 'linux64';
else
    osStr = 'win64';
end
vpixxTrunk = fullfile(toolRoot,'VPixx_Software_Tools','DatapixxToolbox_trunk');
addToPathWithoutGit( fullfile(vpixxTrunk, 'mexdev','build','matlab',osStr) );

% cd(toolRoot);

end %main function



% % % % % % 
% % % % % % 
%% Sub-function dependencies
%  ** These are normal parts of PLDAPS **
%  Sub-function copies are needed here so they can be used while setting up the path
% % % % % % 
% % % % % % 

%% scrubPath.m
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
    fprintf('Removing path directories containing keywords:\n\t[%s\b]\n', sprintf('''%s''\t',excludes{:}));
end


%% addToPathWithoutGit.m
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


