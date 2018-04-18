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

%% set version. make sure to use the git version for better documentation
p.defaultParameters.pldaps.version.number=4.2;
defName = 'glDraw_nonGit';
try
    % Get the current git branch (or tag) name of the PLDAPS codebase in use
    %       (a frustratingly cryptic looking string command...sorry, blame git)
    [err, branchTag] = system( sprintf('git -C %s symbolic-ref -q --short HEAD || git -C %s describe --tags --exact-match', p.trial.pldaps.dirs.proot, p.trial.pldaps.dirs.proot) );
    if err, error(''), end
    p.defaultParameters.pldaps.version.name = branchTag(1:end-1); % remove pesky '\n' at end of returned string
catch
    fprintf(2, '!Notice:\tFailed to retrieve the git branch/tag information from this PLDAPS installation.\n')
    p.defaultParameters.pldaps.version.name = defName;
    fprintf(2, '!Notice:\t    <%s>    will be stored as the version name for now, but follow-up is recommended.\n', p.defaultParameters.pldaps.version.name)
end

p.defaultParameters.pldaps.version.logo='https://motion.cps.utexas.edu/wp-content/uploads/2013/07/platypus-300x221.gif';

% get Matlab version
p.defaultParameters.pldaps.matlabversion = version;

% get Psychtoolbox version
p.defaultParameters.pldaps.psychtoolboxversion = PsychtoolboxVersion;

%multiple sessions not supported for now
p.defaultParameters.session.experimentStart = GetSecs; 

if p.defaultParameters.datapixx.use && Datapixx('IsReady')
    p.defaultParameters.datapixx.experimentStartDatapixx = Datapixx('GetTime');
end

if p.defaultParameters.eyelink.use && Eyelink('IsConnected')
	p.defaultParameters.eyelink.experimentStartEyelink = Eyelink('TrackerTime');
    Eyelink('message', 'BEGINEXPERIMENT');
end