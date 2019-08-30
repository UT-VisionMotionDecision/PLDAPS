function p = startTrial(p)
%pds.eyelink.startTrial    allocate and clear buffer for the next trial
%
% allocates the data structs and also clears the buffer
%
% p = startTrial(p)

if p.trial.eyelink.use
    p.trial.eyelink.sampleNum     = 0;
    p.trial.eyelink.eventNum      = 0;
    p.trial.eyelink.drained       =   false; % drained is a flag for pulling from the buffer
    if ischar(p.trial.eyelink.srate)
        p.trial.eyelink.srate = str2double(p.trial.eyelink.srate); 
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
    
    % Pre clear buffer
    if Eyelink('CheckRecording')~=0
        Eyelink('StartRecording')
    end

    %read from the buffer instead of clearing, must be carefull for long
    %iti 
    p.trial.eyelink.drained=false;
%     pds.eyelink.getQueue(dv);
    p.trial.eyelink.drained = pds.eyelink.clearBuffer(p.trial.eyelink.drained);
end
 