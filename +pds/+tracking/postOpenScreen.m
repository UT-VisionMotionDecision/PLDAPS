function postOpenScreen(p)
% function pds.tracking.postOpenScreen
% 
% Identify tracking source & setup calibration fields
% - Called by pldapsDefaultTrial in state:  experimentPostOpenScreen
% 
% Checks & loads most recent calibration from subject-specific calibration directory:
%   <PLDAPSroot>/rigPrefs/tracking/<subject>/
% New calibrations will be saved in this directory as:
%   ./<subj>_YYYMMDD_<source>.mat
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


%% Create tracking object in p.static
p.static.tracking = pds.tracking.trackObj(p);

% % % DEBUG
% % p.static.tracking.handles.vd
% % notify(p.static.display,'viewDistSet')


%% Initialize calibration matrix with default
% Calibration directory:  (subject-specific)
%   <PLDAPSroot>/rigPrefs/tracking/<subject>
subj = p.trial.session.subject;
if isstring(subj)
    % if "string", just subject name
    subj = char(subj(1));
elseif ischar(subj)
    % do nothing
end

% calibrations stored in subject specific directory:  <pldapsRoot>/rigPrefs/tracking/<subject>
trackingCalDir = fullfile(p.trial.pldaps.dirs.proot, 'rigPrefs', 'tracking', subj);

if ~exist(trackingCalDir,'dir')
    mkdir(trackingCalDir)
end

% Some stereomodes affect screen layout enough to significantly impact calibration
% (e.g. vert/horiz split-screen)
stMode = sprintf('stMode%02d',p.static.display.stereoMode);

% Calibration FileName: new calibrations will be saved as:
%   ./<subj>_YYYMMDD_stMode##_<source>.mat
calFileName = sprintf('%s_%s_%s_%s.mat', subj, datestr(now,'yyyymmdd'), stMode, src);

% Setup calibration in following precident:
%   - Load calibration from file
%   -- default to most recently saved calibration file
%   -- can be overridden by defining fullfile path in:  p.trial.<source>.calSource
%   - Initialize source-specific transform from PLDAPS struct
%   -- p.trial.<source>.tform               (preferred)
%   -- p.trial.<source>.calibration_matrix  (unpreferred)
%   - Fallback to unity transform
% 
if isempty(dir(fullfile(trackingCalDir, [subj,'_*'])))
    % no calibration files in this subject's directory
    if  isfield(p.trial.(src), 'tform') && ~isempty(p.trial.(src).tform)
        % pull calib matrix from (src) if pre-defined
        initTform = p.trial.(src).tform;
        fprintf('\tCalibration transform loaded from PLDAPS class default\n')
        
    elseif isfield(p.trial.(src), 'calibration_matrix') && ~isempty(p.trial.(src).calibration_matrix)
        % create tform from calibration matrix
        initTform = projective2d(p.trial.(src).calibration_matrix);
        fprintf('\tCalibration matrix loaded from PLDAPS class default\n')
        
    else
        initTform = [];
    end
    initCalSource = [];
    
else
    % Select [most] relevant existing calibration
    if isfield(p.trial.(src), 'calSource') && isempty(p.trial.(src).calSource)
        % Predefined calibration source file
        initCalSource = p.trial.(src).calSource;
        if ~exist(initCalSource,'file')
            % if doesn't exist on path, assume is file name w/in trackingCalDir
            initCalSource = fullfile(trackingCalDir, initCalSource);
        end
    else
        % find saved calibrations
        fd = dir(fullfile(trackingCalDir, [subj,'_*']));
        % find files with matching source  [hard limit]
        fd = fd(contains({fd.name}, src));
        % find files with matching source  [soft limit]
        if any(contains({fd.name}, stMode))
            fd = fd(contains({fd.name}, stMode));
        end
        % default to most recent
        if ~isempty(fd)
            [~, i] = max(datenum({fd.date}));
            initCalSource = fullfile(trackingCalDir, fd(i).name);
        else
            % no matches found
            initCalSource = [];
        end
    end
    if ~isempty(initCalSource)
        % load calSource into:  p.static
        loadedCal = load(initCalSource);
        fn = fieldnames(loadedCal);
        if length(fn)==1 && isobject(loadedCal.(fn{1}))
            % update tracking object with loaded properties
            loadedCal = loadedCal.(fn{1});
            fn = properties(loadedCal);
            for i = 1:length(fn)
                if ~isempty(loadedCal.(fn{i})) % skip empty fields
                    p.static.tracking.(fn{i}) = loadedCal.(fn{i});
                end
            end
        elseif isstruct(loadedCal)
            % use struct fields to update tracking object
            p.static.tracking.updateTform(loadedCal);
        else
            fprintf(2, 'Incompatible tracking calibration loaded from:  %s\n', initCalSource)
            keyboard
        end
        
        initTform = p.static.tracking.tform;
        fprintf('\tCalibration loaded from file:\t%s\n', initCalSource)
    else
        fprintf(2, '\tUnable to find compatible tracking calibration for [%s, %s]...\n',subj,src)
        initTform = [];
    end
end

if isempty(initTform)
    % failsafe blank 2nd deg polynomial (best guess if eyetracking)
    initTform = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0], [0 0 1 0 0 0]);
    fprintf('\tCalibration initialized as blank (unity transform)\n')
end


% Avoid dimensionality crash (e.g. if tracking bino, but default only defined for mono)
si = p.trial.tracking.srcIdx;
if max(max(si),numel(si)) > numel(initTform)
    for i = 1:max(si)
        thisTform(i) = initTform( min([i,end]));
    end
    initTform = thisTform;
end


% Apply calibration transform to tracking object
% - do all at once (not by index), else could crash if class of initTform is different from class of [default] tracking tform
p.static.tracking.tform = initTform;

% Run transform update method to ensure consistent with current viewdist parameter
p.static.tracking.updateTform();

% Record paths in p.static.tracking object
p.static.tracking.calPath = struct('source', initCalSource, 'saved',fullfile(trackingCalDir, calFileName));

% Place working copy of calibration transform in PLDAPS p.trial structure
p.trial.(src).tform = p.static.tracking.tform;
% Store frame samples in source
p.trial.(src).posRawFrames = nan(2,max(si),1);
p.trial.(src).posFrames = nan(2,max(si),1);

% Record calibration starting point (incase things get screwy)
p.trial.tracking.t0 = p.trial.(src).tform;



%% updateFxn
% function handle for updating tracked position on each display refresh
% AHCKK!! Function handles in the pldaps struct COMPLETELY BORK TIMING!!
% !~!  Experiment will drop EVERY FRAME just for function handles being present,
% regardless if they're called/used or not!  Must stuff them in p.static
%
%       TODO:  But really must fix properly. This is such a degenerate problem
%
% FIRST: check for updateFxn from <source> field in p.static
% - allows for use of tracking source modules outside of +pds package
if isfield(p.static, src) && isfield(p.static.(src), 'updateFxn')
    p.static.tracking.updateFxn.(src) = p.static.(src).updateFxn;
elseif ~isempty(which(sprintf('pds.%s.updateFxn',src)))
    % NEXT: use default path in PLDAPS +pds package
    %   pds.(module).updateFxn.m
    % -- !! updateFxn must be setup to return handle with appropriate inputs if no inputs provided
    % -- ...if updateFxn doesn't need inputs, use a dummy
    p.static.tracking.updateFxn.(src) = eval(sprintf('@pds.%s.updateFxn;', src)); %eval(sprintf('pds.%s.updateFxn', src));   %
else
    error('PLDAPS:tracking:updateFxn', 'Tracking updateFxn could not be found for source: %s\n\tSee:  help pds.tracking', src)
end



end %main function