function p = trialSetup(p)
% function p = pds.eyelink.trialSetup(p)
% 
% Initialize eyetracker for new trial:
%   - allocate and clear buffer for the next trial
%   - carry over calibration matrix from prior trial (if .eyelink.useRawData & ~isempty(.eyelink.calibration_matrix))
% 
%
% ** replaces pds.eyelink.startTrial for better consistency with role in pldapsDefaultTrial
%
% See also:  pds.eyelink.startTrial
% 
% 2019-07-23  TBC  Transitioned from old fxn

 
if p.trial.eyelink.use
    p.trial.eyelink.sampleNum     = 0;
    p.trial.eyelink.eventNum      = 0;
    p.trial.eyelink.drained       = false; % drained is a flag for pulling from the buffer
    
    % Initialize calibration_matrix (from prior trial or from default)
    if p.trial.eyelink.useRawData
        % calibration matrix initialized by pds.tracking.trialSetup
    end
        
    if p.trial.eyelink.collectQueue
        % returns ALL eyelink samples since last call (...~500-2k Hz)
        bufferSize = p.trial.eyelink.srate * p.trial.pldaps.maxTrialLength;
    else
        % returns ONE eyelink sample per update
        bufferSize = p.trial.display.frate * p.trial.pldaps.maxTrialLength;
    end
    
    % Eyelink only sends these as floats, so no sense in carrying them around as doubles!
    p.trial.eyelink.samples  = nan(p.trial.eyelink.buffersamplelength, bufferSize, 'single');
    p.trial.eyelink.events   = nan(p.trial.eyelink.buffereventlength,  bufferSize, 'single');
    p.trial.eyelink.hasSamples    = true;
    % Eyelink event retrieval only possible from Queued recording
    p.trial.eyelink.hasEvents     = logical(p.trial.eyelink.collectQueue);
    
    % Ensure eyelink is recording
    if Eyelink('CheckRecording')    % Returns 0 if recording in progress.
        Eyelink('StartRecording')
    end

    % clear buffer prior to trial start
    pds.eyelink.clearBuffer(p.trial.eyelink.drained);
    
end
 