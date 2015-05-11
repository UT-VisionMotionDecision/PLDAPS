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
    if ischar(p.trial.eyelink.srate), 
        p.trial.eyelink.srate = str2double(p.trial.eyelink.srate); 
    end
    bufferSize = p.trial.eyelink.srate*p.trial.pldaps.maxTrialLength;
    p.trial.eyelink.samples  = nan(p.trial.eyelink.buffersamplelength,bufferSize);
    p.trial.eyelink.events   = nan(p.trial.eyelink.buffereventlength,bufferSize);
    p.trial.eyelink.hasSamples    = true;
    p.trial.eyelink.hasEvents     = true;
    
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
 