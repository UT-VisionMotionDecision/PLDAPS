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


if strcmpi(src,'eyelink')
    % ALWAYS use raw data for .tracking calibration
    p.trial.eyelink.useRawData = true;
end


% Determine number of source elements (e.g. monocular[1] or binocular[2])
% -!! Must be one-based !!
if isfield(p.trial.(src), 'eyeIdx')
    p.trial.tracking.srcIdx = p.trial.(src).eyeIdx;
    
elseif isfield(p.trial.(src), 'srcIdx')
    p.trial.tracking.srcIdx = p.trial.(src).srcIdx;
    
else
    p.trial.tracking.srcIdx = 1;
end

% nSrc = numel(p.trial.tracking.srcIdx);


% function handle for updating tracked position on each display refresh
% AHCKK!! Function handles in the pldaps struct COMPLETELY BORK TIMING!!
% !~!  Experiment will drop EVERY FRAME just for function handles being present,
% regardless if they're called/used or not!  Must stuff them in p.static
%
%       TODO:  But really must fix properly. This is such a degenerate problem
%
if isfield(p.static, src) && isfield(p.static.(src), 'updateFxn')
    %p.trial.tracking.updateFxn.(src) = p.trial.(src).updateFxn;
    p.static.tracking.updateFxn.(src) = p.static.(src).updateFxn;
else
    % Make an educated guess
    % -- !! updateFxn must be setup to return handle with appropriate inputs if no inputs provided
    % -- ...if updateFxn doesn't need inputs, use a dummy
    p.static.tracking.updateFxn.(src) = eval(sprintf('@pds.%s.updateFxn;', src)); %eval(sprintf('pds.%s.updateFxn', src));   %
end


%% Initialize calibration matrix with default
if  isfield(p.trial.(src), 'tform') && ~isempty(p.trial.(src).tform)
    % pull calib matrix from (src) if pre-defined
    initCalibMatrix = p.trial.(src).tform;
    
elseif isfield(p.trial.(src), 'calibration_matrix') && ~isempty(p.trial.(src).calibration_matrix)
    % create tform from calibration matrix
    initCalibMatrix = projective2d(p.trial.(src).calibration_matrix);

else
    % failsafe blank 2nd deg polynomial (best guess if eyetracking)
    initCalibMatrix = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0], [0 0 1 0 0 0]);

end

% Avoid dimensionality crash (e.g. if tracking bino, but default only defined for mono)
for i = 1:max(p.trial.tracking.srcIdx)
    thisCalib = initCalibMatrix( min([i,end]));

    % p.static.tracking.calib.matrix(i) = thisCalib;
    p.static.tracking.tform(i) = thisCalib;
end

% record starting point (incase things get screwy)
p.trial.tracking.t0 = p.static.tracking.tform;


end %main function