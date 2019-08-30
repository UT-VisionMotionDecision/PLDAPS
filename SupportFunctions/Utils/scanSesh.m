function [tt, seshDat] = scanSesh(baseName, basePath, dontAsk)

% Base Path (usually the recording day directory)
if nargin<2 || isempty(basePath)
    basePath = pwd;
end

if nargin<3 || isempty(dontAsk)
    dontAsk = 0;
end

if nargin<1 || isempty(baseName)
    fd = dir(fullfile(basePath, 'pds', '*.PDS'));
    if ~dontAsk
        [fd, ok] = chooseFile(fd, 'Select PLDAPS data file(s):', [],'all');
        if ~ok, tt = []; return, end
    end
else
    fd = dir(fullfile(basePath,'pds',['*',baseName,'*.PDS']));
end


% trim by nPasses first (skips junky parameter setting files)
for i = 1:length(fd),
    cm(i) = load(fullfile(fd(i).folder,fd(i).name),'-mat','condMatrix');
end
% extract nPasses
nPasses = arrayfun(@(x) x.condMatrix.iPass, cm)';
ii = nPasses>1;

fd = fd(ii);
cm = cm(ii);

for i = 1:length(fd),
    % load baseParams for each remaining file
    pb(i) = load(fullfile(fd(i).folder,fd(i).name),'-mat','baseParams');
end

%%
% split file name into parts by '_' & '.'
sesh        = arrayfun(@(x) strsplit(x.baseParams.session.file,{'_','.'}), pb, 'uni',0);
nn  = cellfun(@numel, sesh);
if numel(unique(nn))>1
    warning('Skipping incompatible entries from scanSesh:\n')%
    for jj = find(nn~=5)
        fprintf(2, '\t%s\n', sprintf('%s\t',sesh{jj}{:}))
    end

%     sesh    %#ok<NOPRT>
    sesh = sesh(nn==5);
    % extra descriptors get messy...try workaround or just deselect problem file 
end
sesh        = reshape(decellify(sesh), [length(sesh{1}), length(sesh)])';

% Viewing distance
viewDist        = arrayfun(@(x) x.baseParams.display.viewdist, pb)';

% compile summary params & info
subj        = sesh(:,1);
plx         = sesh(:,2);
loc         = sesh(:,3);
pdsTime     = sesh(:,end-1);

exptName    = arrayfun(@(x) x.baseParams.session.caller.name, pb, 'uni',0)';
nTrials         = arrayfun(@(x) x.baseParams.pldaps.iTrial, pb)';
durMin         = arrayfun(@(x) diff(x.baseParams.datapixx.timestamplog(1,[1,end]))/60, pb)';
nPasses         = arrayfun(@(x) x.condMatrix.iPass, cm)';

fpath       = arrayfun(@(x) fullfile(x.folder, x.name), fd, 'uni',0);

% tt = table('subj', {fd.name}', 'expt',expName, 'trials',ntr, 'Passes',npa);
tt = table(subj, plx, loc, pdsTime, exptName, viewDist, nPasses, nTrials, durMin);   %'expt',expName, 'trials',ntr, 'Passes',npa);
% sort by PLDAPS session time
tt = sortrows(tt,'pdsTime');
% linear index var (for ease of use)
idx = (1:size(tt,1))';
tt = [table(idx), tt];

% detailed outputs
if nargout>1
    seshDat = struct;
    for i = 1:length(fd)
        seshDat(i).pdsSrc = fd(i);
        seshDat(i).condMatrix = cm(i).condMatrix;
        seshDat(i).baseParams = pb(i).baseParams;
    end
end

end
