function [pds, pdsName] = pdsCombineTempFiles(baseName, basePath)
% function [pds, pdsName] = pdsCombineTempFiles(baseName, basePath)
% 
% Recovery function for compiling PDS output from a set of temp files
%   (i.e. after a crash during experiment)
% 
% 2020-09-03 TBC  Updating ancient/psuedocode to modern pldaps
% 


%   !!! Figure out a way to save TEMP files better, so that a record of components outside of
%       the [p.trial] field can be accounted for (...at least in their initial state)

% % NOTE:
% % Currently unable to recreate some [important] elements of output struct:
% %     .condMatrix  (or .conditions)
% %     .static
% %     .pdsCore
% % 


%% Parse inputs
% Base Path (usually the recording day directory)
if nargin<2 || isempty(basePath)
    basePath = pwd;
end
% clean up path
basePath = homeTilda(basePath);

% PDS file selection modal if [baseName] not specified
if nargin<1
    baseName = [];
end


%% Find matching PDS files
fd = dir(fullfile(basePath, [baseName,'*.PDS']));
if isempty(fd)
    % try standard pds sub-directory
    fd = dir(fullfile(basePath, 'pds', [baseName,'*.PDS']));
end

nTrials = length(fd);
fprintf('\n~~~\tLoading & compiling %d temp trial files matching:\t"%s*.PDS" \n\tfrom:\t%s\n',nTrials, baseName, basePath)
% Make progress bar object for command window output
try
    pb = progBar(2:nTrials, min(30,nTrials));
end


%% ReCreate PDS output structure (...as best we can)
% initialize (prevent confusion with possible fxns on path)
pds = struct;
[pds.baseParams,pds.condMatrix,pds.pdsCore,pds.static] = deal([]);
[pds.conditionNames,pds.conditions,pds.data]=deal({});
verbo = 0; % 0 == silence output from pdsImport


%% Create baseParams
% load first trial struct (this should be "trial00000", which is saved out before PLDAPS trial loop begins)
p = load(fullfile(fd(1).folder, fd(1).name),'-mat');
fn = fieldnames(p);
if length(fn)==1 && isa(p.(fn{1}),'pldaps')
    % initial save was complete pldaps object (expected)
    p = p.(fn{1});
    pds = p.save;   %pds.baseParams = p.trial;
else
    % initial save was struct version of p.trial before experiment start
    pds.baseParams = pdsImport(fullfile(fd(1).folder, fd(1).name), [], verbo);
    % must create a 'dummy' pldaps object based on the baseParams
    %   - allows use of standard pldaps class methods (e.g. getDifferenceFromStruct)
    p = pldaps(pds.baseParams.session.subject, pds.baseParams);
end
% TODO: !!! Figure out a way to save TEMP files better, so that a record of components outside of
%       the [p.trial] field is saved (...at least in their initial state)



%% Compile all trial files into .data{}
for i = 2:nTrials
    % Load each trial
    thisTr = pdsImport(fullfile(fd(i).folder, fd(i).name), [], verbo);
    % Determine difference from initial struct & add to .data
    pds.data{thisTr.trialnumber} = getDifferenceFromStruct(p.defaultParameters, thisTr);
    % update progress
    if exist('pb','var')
        pb.check(i);
    end
end


%% Record info about reconstruction
pds.reconSrc.path = basePath;
pds.reconSrc.name = {fd.name};
% update file name to reflect reconstruction
pds.baseParams.session.fileOrig = pds.baseParams.session.file;
[fp,fn,fe] = fileparts(pds.baseParams.session.file);
pdsName = fullfile([fn,'-recon',fe]);
pds.baseParams.session.file = pdsName;



end % main function



% % % % % % % %
% % % % % % % %
%% SubFunctions
% % % % % % % %
% % % % % % % %


%% homeTilda
function outPath = homeTilda(inPath)
% shorten $HOME path to "~"
%

if isunix % mac or linux
    [~,homeDir] = unix('echo $HOME');
    homeDir = homeDir(1:end-1);
    
    if contains(inPath, homeDir)
        i = strfind(inPath, homeDir);
        inPath(i:length(homeDir)) = [];
        outPath = fullfile('~',inPath);
    else
        % do nothing
        outPath = inPath;
    end
    
else
    % Windoze...do nothing
    outPath = inPath;
end

end %homeTilda
