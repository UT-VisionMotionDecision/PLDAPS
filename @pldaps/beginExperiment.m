function p = beginExperiment(p)
%beginExperiment    initialize an Exeriment
% p = beginExperiment(p)
% initialize the beginning of time for this experiment
% beginExperiment checks which devices are connected to PLDAPS and gets
% timestamps from each of them and stores them in the devives substructures
% of p.defeaultParameters

% 12/2013 jly   wrote it
% 01/2014 jly   make sure Eyelink is connected before trying to get time
%               from it
% 05/2015 jk    adapted it to pldaps 4.1
% 10/2016 jk    bumped version to 4.2
% 2018-04-18 tbc    Updated to query git branch/tag name
%                   otherwise, default to hardcoded string
% 2018-05-01 tbc    Expanded git version tracking information

%% get PLDAPS version
% Pldaps root directory shorthand
proot = p.trial.pldaps.dirs.proot;
% Go to pldaps root dir to execute the following git commands (...could use -C flag, but makes this code gangly & unreadable)
here = pwd;
cd(proot);

defName = 'glDraw_nonGit';
p.trial.pldaps.version.number = 4.2;

[name, remoteUrl, commit, info, status, gdiff] = deal([]);
try
    % Retrieve Git info of the PLDAPS codebase in use
    % Branch or tag name       (a frustratingly cryptic looking string command...such is git.)
    [err, name] = system( 'git symbolic-ref -q --short HEAD || git describe --tags --exact-match --long' );
    name(name==10) = []; % remove pesky '\n' at end of returned string
    
    % URL of the remote repository (identifies source fork of this install)
    [err, remoteUrl] = system( 'git config --get remote.origin.url' );
    remoteUrl(remoteUrl==10) = []; % remove pesky '\n' at end of returned string
    
    % Full hash of most recent commit
    [err, commit] = system( 'git --no-pager show -s --pretty=format:''%H''' );
    
    % Info on commit state, tags, date, 
    [err, info] = system( 'git --no-pager show -s --pretty=format:''%h %d %ci''' );
    info(info==10) = []; % remove pesky '\n' at end of returned string
    
    % Status of local repo
    [err, status] = system( 'git --no-pager status -s');
    
    if ~err && ~isempty(status)
        status = [sprintf('Locally modified:\n-------------------------------\n'), status];
        [err, gdiff] = system('git --no-pager diff --minimal -U2');
    end
catch
    fprintf(2, '!Notice:\tFailed to retrieve the git branch/tag information from this PLDAPS installation.\n')
    name = defName;
    fprintf(2, '!Notice:\t    <%s>    will be stored as the version name for now, but follow-up is recommended.\n', p.trial.pldaps.version.name)
end

% Compile outputs into version struct
p.trial.pldaps.version.name = name;
p.trial.pldaps.version.remoteUrl = remoteUrl;
p.trial.pldaps.version.commit = commit;
p.trial.pldaps.version.info = info;
p.trial.pldaps.version.status = status;
p.trial.pldaps.version.diff = gdiff;

% If a specific commit/tag state of the PLDAPS repository was requested,
% check that it matches current.  Error & alert user if not.
if isfield(p.trial.pldaps.version, 'tag') && ~isempty(p.trial.pldaps.version.tag)
    tagRequested = p.trial.pldaps.version.tag;
    if isempty(strfind(info, ['tag: ',tagRequested])) || ~strcmpi(commit(1:length(tag)), tagRequested)
        fprintf(2, [fprintLineBreak fprintLineBreak...
            'Error:  PLDAPS source does not match the requested tag/commit:\n'...
            '\tRequested tag/commit:\t%s\n'...
            '\t\tCurrent version:\t%s\n'...
            fprintLineBreak fprintLineBreak], tagRequested, info);
        fprintf('Resolve by checking out proper PLDAPS state from git repository,\nor clearing\n\t\tp.trial.pldaps.version.tag\nbefore beginning experiment.\n\n');
        fprintLineBreak, fprintLineBreak 
        error('pldaps:beginExperiment:versionCheck', '');
    end
end


p.trial.pldaps.version.logo='https://motion.cps.utexas.edu/wp-content/uploads/2013/07/platypus-300x221.gif';

% return to starting directory
cd(here);

%% get Matlab version
p.trial.pldaps.matlabversion = version;

%% get Psychtoolbox version
p.trial.pldaps.psychtoolboxversion = PsychtoolboxVersion;


%% Compile experiment start time(s) from devices
p.trial.session.experimentStart = GetSecs; 

if p.trial.datapixx.use && Datapixx('IsReady')
    p.trial.datapixx.experimentStartDatapixx = Datapixx('GetTime');

    % ~~~ No. Repurposing strobes as text communication is not good ~~~ --TBC 2018
    % OK idea, but muddles what unique strobed values "mean" within the PLX file, and 
    % still doesn't solve problem in the other direction; knowing what the PLX/spike
    % filename is from the PDS file.
    % %     % Send PDS filename as strobed word
    % %     if ~isempty(p.trial.session.file)
    % %         for i = 1:numel(p.trial.session.file)
    % %             pds.datapixx.strobe( double(p.trial.session.file(i)) );
    % %         end
    % %     end
    
end

if p.trial.eyelink.use && Eyelink('IsConnected')
	p.trial.eyelink.experimentStartEyelink = Eyelink('TrackerTime');
    Eyelink('message', 'BEGINEXPERIMENT');
end


end