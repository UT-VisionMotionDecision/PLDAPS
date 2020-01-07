function postOpenScreen(p)
% function pds.tracking.postOpenScreen
% 
% Identify tracking source & setup calibration fields
% - Called by pldapsDefaultTrial in state:  experimentPostOpenScreen
% 

% identify source (def: 'eyelink')
if isfield(p.trial.pldaps.modNames, 'tracker')
    p.trial.tracking.source = p.trial.pldaps.modNames.tracker{1};
else
    p.trial.tracking.source = 'eyelink';
end
src = p.trial.tracking.source;

% determine number of source elements (e.g. monocular[1] or binocular[2])
if isfield(p.trial.(src), 'eyeIdx')
    p.trial.tracking.srcIdx = p.trial.(src).eyeIdx;
else
    p.trial.tracking.srcIdx = 1;
end
nSrc = numel(p.trial.tracking.srcIdx);

% function handle for updating tracked position on each display refresh
if isfield(p.trial.(src), 'updateFxn')
    p.trial.tracking.updateFxn.(src) = p.trial.(src).updateFxn;
else
    p.trial.tracking.updateFxn.(src) = eval(sprintf('@pds.%s.updateFxn;', src));
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
        thisMatrix = initCalibMatrix(ii);
    elseif ~isempty(initCalibMatrix)
        ii = min([i, size(initCalibMatrix, 3)]);
        thisMatrix = projective2d(initCalibMatrix(:,:,ii));    % affine2d;
    else
        thisMatrix = projective2d;
    end
    p.static.tracking.calib.matrix(i) = thisMatrix;
end

p.trial.tracking.cm0 = cat(3, p.static.tracking.calib.matrix.T);
% initialize zeroed-out adjustment params
p.static.tracking.adjust.val(1:nSrc) = struct('gainX',0, 'gainY',0, 'offsetX',0, 'offsetY',0, 'theta',0);


% % [gainX, gainY, offsetX, offsetY, theta] = matrix2Components(p.trial.tracking.calib.matrix);
% % 
% % 
% % for i = 1:nSrc
% %     s = p.trial.tracking.adjust.val(i);
% %     s.gainX   = gainX(i);
% % 	s.gainY   = gainY(i);
% % 	s.offsetX = offsetX(i);
% % 	s.offsetY = offsetY(i);
% %     s.theta   = theta(i);
% %     
% %     sinTh = sind(s.theta);
% %     cosTh = cosd(s.theta);
% %     
% %     %     R = [cosTh -sinTh; sinTh cosTh; 0 0] .* [s.gainX s.gainX; s.gainY s.gainY; 0 0];
% %     %     S = [0 0; 0 0; s.offsetX s.offsetY];
% %     %     C = R + S;
% %     
% %     % initialize components
% %     [T, R, S] = deal(eye(3));
% %     % rotate
% %     R([1,2],[1,2]) = cosTh * [1 1];
% %     R([2,1],[1,2]) = sinTh * [-1 1];
% %     % translate
% %     T(3,1) = s.offsetX;
% %     T(3,2) = s.offsetY;
% %     % scale
% %     S(1,1) = s.gainX;
% %     S(2,2) = s.gainY;
% %     
% %     % Combined calibration matrix
% %     C = R * T * S;
% %     % NOTE: R*T*S order important for component extraction with pds.tracking.matrix2Components.m
% %     
% %     s.R = R;
% %     s.T = T;
% %     s.S = S;
% %     s.C = C;
% %     
% %     p.trial.tracking.adjust.val(i) = s;
% % end

% % p.trial.tracking.adjust.raw = nan(p.trial.pldaps.maxFrames, 3);