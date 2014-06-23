function dv = startTrial(dv)
% [drained, samplesIn, eventsIn] = pds.eyelink.startTrial(dv)

if dv.trial.eyelink.use
    dv.trial.eyelink.sampleNum     = 1;
    dv.trial.eyelink.eventNum      = 1;
    dv.trial.eyelink.drained       =   false; % drained is a flag for pulling from the buffer
    if ischar(dv.trial.eyelink.srate), 
        dv.trial.eyelink.srate = str2double(dv.trial.eyelink.srate); 
    end
    bufferSize = dv.trial.eyelink.srate*dv.trial.eyelink.maxTrialLength;
    dv.trial.eyelink.samples  = nan(dv.trial.eyelink.buffersamplelength,bufferSize);
    dv.trial.eyelink.events   = nan(dv.trial.eyelink.buffereventlength,bufferSize);
    dv.trial.eyelink.hasSamples    = true;
    dv.trial.eyelink.hasEvents     = true;
    
    % Pre clear buffer
    if Eyelink('CheckRecording')~=0
        Eyelink('StartRecording')
    end

    %read from the buffer instead of clearing, must be carefull for long
    %iti 
    dv.trial.eyelink.drained=false;
%     pds.eyelink.getQueue(dv);
    dv.trial.eyelink.drained = pds.eyelink.clearBuffer(dv,dv.trial.eyelink.drained);
end
 