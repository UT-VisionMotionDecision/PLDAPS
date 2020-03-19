function p = setup(p, sn)
% function p = pds.tracking.setup(p)
% 
% Setup & initialization of tracking module for tracking binocular or monocular eye position,
% or [potentially] other devices/things.
% -- This function gets called by pldapsDefaultTrial.m, prior to opening the PTB screen
% -- It setsup the tracking module to be executed immediately after the default trial function
% -- Additional setup (incl. determining tracking source) occurs in pds.tracking.postOpenScreen
% 
% =======
% Activate calibration trial from pause state by calling:
%       pds.tracking.runCalibrationTrial(p)  % i.e. nargin==1
% 
% How is the .tracking module different from direct usage (e.g. p.trial.eyelink)?
%   (1) it takes care of device calibration, allowing for monocular or [truly] binocular eyetracking,
%       and gives user more active control to save/recall/manipulate the mapping of tracker-to-world
%   (2) allows experiment code to be more ambiguous to what is being tracked (e.g. eye, hand, mouse)
%       and ambiguous to the particular device is being used (e.g. eyelink, LeapMotion, Vpixx, etc)
% 
% See also:  pds.tracking.runCalibrationTrial, pds.tracking.postOpenScreen
% 
% 2020-01-xx  TBC  Wrote it.
% 2020-03-03  TBC  Cleaning.
% 

% Set module order to run immediately after calling module (pldapsDefaultTrial.m)
snMod = 'tracking';
tmp =  pldapsModule('modName',snMod, 'name','pds.tracking.runCalibrationTrial', 'order', p.trial.(sn).stateFunction.order+1);%,...
    % 'requestedStates', {'frameUpdate','framePrepareDrawing','frameDraw','frameGLDrawLeft','frameGLDrawRight','trialItiDraw','trialSetup','trialPrepare','trialCleanUpandSave','experimentPreOpenScreen','experimentPostOpenScreen','experimentCleanUp'}); % ...does setting up in 'experimentPreOpenScreen' preclude this module running in that state??

% .on should not be manually activated
tmp.on = false;
fn = fieldnames(tmp);
for i = 1:length(fn)
    p.trial.(snMod).(fn{i}) = tmp.(fn{i});
end


% % % 
% % % % identify source (def: 'eyelink')
% % % if isfield(p.trial.pldaps.modNames, 'tracker')
% % %     p.trial.tracking.source = p.trial.pldaps.modNames{1};
% % % else
% % %     p.trial.tracking.source = 'eyelink';
% % % end
% % % src = p.trial.tracking.source;
% % % 
% % % 
% % % % % determine number of source elements (e.g. monocular[1] or binocular[2])
% % % % if isfield(p.trial.(src), 'eyeIdx')
% % % %     p.trial.tracking.srcIdx = p.trial.(src).eyeIdx;
% % % % else
% % % %     p.trial.tracking.srcIdx = 1;
% % % % end
% % % nSrc = numel(p.trial.tracking.srcIdx);
% % % 
% % % % % initialize calibration matrix
% % % % if isempty(p.trial.tracking.calib.matrix)
% % % %     for i = 1:nSrc
% % % %         p.trial.tracking.calib.matrix(i) = projective2d;    % affine2d;
% % % %     end
% % % % end
% % % 
% % % % if isfield(p.trial.(src), 'calibration_matrix') && ~isempty(p.trial.(src).calibration_matrix)
% % % %     for i = 1:nSrc
% % % %         ii = min([i, size(p.trial.(src).calibration_matrix,3)]); % prevent dimensionality crash
% % % %         p.trial.tracking.calib.matrix(i).T = p.trial.(src).calibration_matrix(:,:,ii);
% % % %     end
% % % % end
% % % 
% % % % C =[1 0; 0 1; 0 0]; % assume default calibration
% % % 
% % % % if p.trial.eyelink.use && p.trial.eyelink.useAsEyepos && p.trial.eyelink.useRawData
% % % %     if ~isfield(p.trial.eyelink, 'eyeIdx')
% % % %         eyeIdx = 1;
% % % %     else
% % % %         eyeIdx=p.trial.eyelink.eyeIdx;
% % % %     end
% % % %     
% % % %     C = p.trial.eyelink.calibration_matrix(:,:,eyeIdx)';
% % % % end
% % % 
% % % 
% % % % [gainX, gainY, offsetX, offsetY, theta] = matrix2Components(p.trial.tracking.calib.matrix);
% % % 
% % % 
% % % for i = 1:nSrc
% % %     s = p.trial.tracking.adjust.val(i);
% % %     s.gainX   = gainX(i);
% % % 	s.gainY   = gainY(i);
% % % 	s.offsetX = offsetX(i);
% % % 	s.offsetY = offsetY(i);
% % %     s.theta   = theta(i);
% % %     
% % %     sinTh = sind(s.theta);
% % %     cosTh = cosd(s.theta);
% % %     
% % %     %     R = [cosTh -sinTh; sinTh cosTh; 0 0] .* [s.gainX s.gainX; s.gainY s.gainY; 0 0];
% % %     %     S = [0 0; 0 0; s.offsetX s.offsetY];
% % %     %     C = R + S;
% % %     
% % %     % initialize components
% % %     [T, R, S] = deal(eye(3));
% % %     % rotate
% % %     R([1,2],[1,2]) = cosTh * [1 1];
% % %     R([2,1],[1,2]) = sinTh * [-1 1];
% % %     % translate
% % %     T(3,1) = s.offsetX;
% % %     T(3,2) = s.offsetY;
% % %     % scale
% % %     S(1,1) = s.gainX;
% % %     S(2,2) = s.gainY;
% % %     
% % %     % Combined calibration matrix
% % %     C = R * T * S;
% % %     % NOTE: R*T*S order important for component extraction with pds.tracking.matrix2Components.m
% % %     
% % %     s.R = R;
% % %     s.T = T;
% % %     s.S = S;
% % %     s.C = C;
% % %     
% % %     p.trial.tracking.adjust.val(i) = s;
% % % end
% % % 
% % % p.trial.tracking.adjust.raw = nan(p.trial.pldaps.maxFrames, 3);