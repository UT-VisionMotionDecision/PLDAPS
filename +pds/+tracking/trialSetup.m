function p = trialSetup(p)
% function p = pds.tracking.trialSetup(p)
% 
% 
% Initialize [eye]tracking for new trial:
%   - allocate and clear buffer for the next trial
%   - carry over calibration matrix from prior trial (if .eyelink.useRawData & ~isempty(.eyelink.calibration_matrix))
% 
% NOTE: excised usage of  pds.tracking.updateMatrix.m
%       - May be useful to add back, if written to check for nSource or more modular tasks
%       are needed here.
%
% See also:  pds.eyelink.startTrial
% 
% 2019-07-23  TBC  Transitioned from old fxn
% 2020-01-13  TBC  Refining for pds.tracking
    

% update active calibration matrix from static storage
p.trial.tracking.calib.matrix = p.static.tracking.calib.matrix;
% place copy in tracking source struct/module too
p.trial.(p.trial.tracking.source).calibration_matrix = p.static.tracking.calib.matrix;