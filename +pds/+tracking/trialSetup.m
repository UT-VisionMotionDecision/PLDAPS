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
    

% update active calibration matrix from storage in p.static.tracking object
p.trial.tracking.tform = p.static.tracking.tform;

% place copy in tracking source struct/module too
% - Added "tracking_" to source field name to prevent overwriting different transform in source module
p.trial.(p.trial.tracking.source).tracking_tform = p.static.tracking.tform;