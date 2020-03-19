function postOpenScreen(p)
% function pds.tracking.postOpenScreen
% 
% Identify tracking source & setup calibration fields
% - Called by pldapsDefaultTrial in state:  experimentPostOpenScreen
% 

% Identify source (def: 'eyelink')
if isfield(p.trial.pldaps.modNames, 'tracker')
    p.trial.tracking.source = p.trial.pldaps.modNames.tracker{1};
else
    p.trial.tracking.source = 'eyelink';
end
src = p.trial.tracking.source;

% ALWAYS use raw data for .tracking calibration
switch src
    case 'eyelink'
        p.trial.eyelink.useRawData = true;
        % DEBUG: may need to override this when using mouse simulation mode (eyelink 1000)
end

fprintLineBreak
fprintf('Tracking Module::\tInitializing source [%s]\n',src)

% Determine number of source elements (e.g. monocular[1] or binocular[2])
% -!! Must be one-based !!
if isfield(p.trial.(src), 'eyeIdx')
    p.trial.tracking.srcIdx = p.trial.(src).eyeIdx;
    
elseif isfield(p.trial.(src), 'srcIdx')
    p.trial.tracking.srcIdx = p.trial.(src).srcIdx;
    
else
    p.trial.tracking.srcIdx = 1;
end


% function handle for updating tracked position on each display refresh
% AHCKK!! Function handles in the pldaps struct COMPLETELY BORK TIMING!!
% !~!  Experiment will drop EVERY FRAME just for function handles being present,
% regardless if they're called/used or not!  Must stuff them in p.static
%
%       TODO:  But really must fix properly. This is such a degenerate problem
%
if isfield(p.static, src) && isfield(p.static.(src), 'updateFxn')
    p.static.tracking.updateFxn.(src) = p.static.(src).updateFxn;
else
    % Make an educated guess
    % -- !! updateFxn must be setup to return handle with appropriate inputs if no inputs provided
    % -- ...if updateFxn doesn't need inputs, use a dummy
    p.static.tracking.updateFxn.(src) = eval(sprintf('@pds.%s.updateFxn;', src)); %eval(sprintf('pds.%s.updateFxn', src));   %
end


%% Initialize calibration matrix with default
% Subject specific calibration directory
subj = char(p.trial.session.subject(1));
trackingCalDir = fullfile(p.trial.pldaps.dirs.proot, 'rigPrefs', 'tracking', subj);

if ~exist(trackingCalDir,'dir')
    mkdir(trackingCalDir)
end

if isempty(dir(fullfile(trackingCalDir, [subj,'_*'])))
    if  isfield(p.trial.(src), 'tform') && ~isempty(p.trial.(src).tform)
        % pull calib matrix from (src) if pre-defined
        initTform = p.trial.(src).tform;
        fprintf('Calibration loaded from PLDAPS class default')
        
    elseif isfield(p.trial.(src), 'calibration_matrix') && ~isempty(p.trial.(src).calibration_matrix)
        % create tform from calibration matrix
        initTform = projective2d(p.trial.(src).calibration_matrix);
        fprintf('Calibration loaded from PLDAPS class default')
        
    else
        % failsafe blank 2nd deg polynomial (best guess if eyetracking)
        initTform = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0], [0 0 1 0 0 0]);
        fprintf('Calibration initialized as blank (unity transform)')
        
    end
    initCalSource = [];
    
else
    if isfield(p.trial.(src), 'calSource') && isempty(p.trial.(src).calSource)
        initCalSource = p.trial.(src).calSource;
        if ~exist(initCalSource,'file')
            % if doesn't exist on path, assume is file name w/in trackingCalDir
            initCalSource = fullfile(trackingCalDir, initCalSource);
        end
    else
        % find saved calibrations
        fd = dir(fullfile(trackingCalDir, [subj,'_*']));
        % limit matches to this source
        fd = fd(contains({fd.name}, src));
        % default to most recent
        [~, i] = max(datenum({fd.date}));
        initCalSource = fullfile(trackingCalDir, fd(i).name);
    end
    % load calSource into:  p.static
    p.static.tracking = load(initCalSource);
    
    initTform = p.static.tracking.tform;
    fprintf('Calibration loaded from file:\n\t%s\n', initCalSource)
    
end

calFileName = sprintf('%s_%s_%s.mat', subj, datestr(now,'yyyymmdd'), src);
p.static.tracking.calPath = struct('source', initCalSource, 'saved',fullfile(trackingCalDir, calFileName));

% Avoid dimensionality crash (e.g. if tracking bino, but default only defined for mono)
for i = 1:max(p.trial.tracking.srcIdx)
    thisCalib = initTform( min([i,end]));

    % p.static.tracking.calib.matrix(i) = thisCalib;
    p.static.tracking.tform(i) = thisCalib;
end

p.trial.(src).tform = p.static.tracking.tform;
% record starting point (incase things get screwy)
p.trial.tracking.t0 = p.static.tracking.tform;


end %main function