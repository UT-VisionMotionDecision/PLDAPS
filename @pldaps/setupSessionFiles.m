function p = setupSessionFiles(p)
% function p = setupSessionFiles(p)
% 
% Setup necessary directories and filenames for this PLDAPS session
%   -- Called by pldaps.run
%
% 2018-09-13  TBC  Wrote to move clutter out of pldaps.run

if p.defaultParameters.pldaps.nosave
    p.defaultParameters.session.file='';
    p.defaultParameters.session.dir='';
    
else
    % Compile file & session name components
    sessionDateStr = datestr(p.defaultParameters.session.initTime, 'yyyymmdd');
    sessionTimeStr = datestr(p.defaultParameters.session.initTime, 'HHMM');
    subjStr = p.defaultParameters.session.subject; % subject name
    labelStr = p.defaultParameters.session.experimentSetupFile; % session label
    % if subject is string array (Matlab >2017), use second element as 
    if isa(subjStr, 'string') 
        labelStr = [labelStr, char(subjStr(1,2))];
        subjStr = subjStr(1,1);
    end
    % ...clean up formatting for file name
    if ~isempty(subjStr)
        subjStr = sprintf('%s_', subjStr);
    end
    if ~isempty(labelStr)
        labelStr = sprintf('%s', labelStr);
    end

    % SessionDate sub-directory
    p.defaultParameters.session.dir = fullfile(p.defaultParameters.pldaps.dirs.data, sessionDateStr);
    if ~exist(p.defaultParameters.session.dir, 'dir')
        mkdir(p.defaultParameters.session.dir)
    end

    % Session filename
    p.defaultParameters.session.file = sprintf('%s%s%s_%s.PDS',...
        subjStr,...
        sessionDateStr,...
        labelStr, ...
        sessionTimeStr);
    
    if p.defaultParameters.pldaps.useFileGUI
        [cfile, cdir] = uiputfile('.PDS', 'specify data storage file', fullfile( p.defaultParameters.session.dir,  p.defaultParameters.session.file));
        if isnumeric(cfile) % canceled
            error('pldaps:run',['!!!\tFile selection canceled. When .pldaps.useFileGUI is enabled,\n',...
                '!!!\tuser MUST supply save filename & location in gui. I cannot go on.\n\tAborting.\n']);
        end
        p.defaultParameters.session.dir = cdir;
        p.defaultParameters.session.file = cfile;
    end
    
    if ~exist(p.trial.session.dir, 'dir')
        warning('pldaps:run','Data directory specified in .pldaps.dirs.data does not exist.\n');
        ans = input(sprintf('\tShould I create Data & TEMP dirs in: %s? (...if not, will quit PLDAPS)\n\t\t(y/n): ',p.trial.pldaps.dirs.data), 's');
        if ~isempty(ans) && lower(ans(1))=='y'
            mkdir(fullfile(p.trial.pldaps.dirs.data));
            mkdir(fullfile(p.trial.pldaps.dirs.data, 'TEMP'));
        else
            fprintf(2, '\n\tQuitting PLDAPS. Please run createRigPrefs to update your data dirs,\n\tor create directory %s, containing a subdirectory called ''TEMP''\n\n', p.trial.pldaps.dirs.data)
            return;
        end
    end
    % Data types sub-directoies
    shhhh = warning('off', 'MATLAB:MKDIR:DirectoryExists'); % shhhh...just do it
    mkdir(fullfile(p.trial.session.dir, 'eye'))
    mkdir(fullfile(p.trial.session.dir, 'pds'))
    mkdir(fullfile(p.trial.session.dir, 'spk'))
    warning(shhhh)
    
end

end %end setupSessionFiles.m