function matrixOutput = updateMatrix(p)
% function pds.tracking.updateMatrix(p)
% 
% Update calibration matrix for this trial to the calibrated copy in  p.static.tracking.calib
% - ensure that each trial has a copy of the calibration used
% - allows updates to calibration to carry over across trials
% 
% See also:  pds.tracking.trialSetup
% 
% 
% 2020-01-xx  TBC  Wrote it.


% Manual calibration adjustments not implemented...not a high priority, proper calibration is a better goal.
%   - See older git versions of this file for WIP code to that end.


% Update active calibration matrix in  p.trial
p.trial.tracking.tform = p.static.tracking.tform;

% %  Should we be checking that nSources in p.static matches expectation of this trial??  ...how?
% nSrc = numel(p.trial.tracking.srcIdx);

if nargout==0
    return
else
    matrixOutput = p.static.tracking.tform;%p.trial.tracking.calib.matrix;
end