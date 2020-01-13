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
if isfield(p.trial.(src), 'eyeIdx')
    p.trial.tracking.srcIdx = p.trial.(src).eyeIdx;
else
    p.trial.tracking.srcIdx = 1;
end
nSrc = numel(p.trial.tracking.srcIdx);


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
if isfield(p.trial.(src), 'calibration_matrix') && ~isempty(p.trial.(src).calibration_matrix)
    % pull calib matrix from (src) if pre-defined
    initCalibMatrix = p.trial.(src).calibration_matrix;

elseif isField(p.trial, 'tracking.calib.matrix') && ~isempty(p.trial.tracking.calib.matrix)
    % else from .tracking if pre-defined
    initCalibMatrix = p.trial.tracking.calib.matrix;
else
    % failsafe
    initCalibMatrix = eye(3);

end

for i = 1:nSrc
    % avoid dimensionality crash (e.g. if tracking bino, but default only defined for mono)
    if isa(initCalibMatrix, 'images.geotrans.internal.GeometricTransformation')
        ii = min([i, length(initCalibMatrix)]);
        thisCalib = initCalibMatrix(ii);
        
    elseif ~isempty(initCalibMatrix)
        ii = min([i, size(initCalibMatrix, 3)]);
        thisCalib = projective2d(initCalibMatrix(:,:,ii));    % affine2d;
        
    else
        thisCalib = projective2d;
    end
    % TODO:  Should fix this to tform NOW, instead of coding for the [non-existent] past
    p.static.tracking.calib.matrix(i) = thisCalib;
    
end

p.trial.tracking.cm0 = cat(3, p.static.tracking.calib.matrix.T);
% initialize zeroed-out adjustment params
p.static.tracking.adjust.val(1:nSrc) = struct('gainX',0, 'gainY',0, 'offsetX',0, 'offsetY',0, 'theta',0);


end %main function