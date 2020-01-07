function p = trialSetup(p)
% function p = pds.tracking.trialSetup(p)
% 
% 
% Initialize [eye]tracking for new trial:
%   - allocate and clear buffer for the next trial
%   - carry over calibration matrix from prior trial (if .eyelink.useRawData & ~isempty(.eyelink.calibration_matrix))
% 
%
% ** replaces pds.eyelink.startTrial for better consistency with role in pldapsDefaultTrial
%
% See also:  pds.eyelink.startTrial
% 
% 2019-07-23  TBC  Transitioned from old fxn
    

% update active calibration matrix from static storage
p.trial.(p.trial.tracking.source).calibration_matrix = pds.tracking.updateMatrix(p);
