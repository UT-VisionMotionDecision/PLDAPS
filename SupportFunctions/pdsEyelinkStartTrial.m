function dv = pdsEyelinkStartTrial(dv)
% [drained, samplesIn, eventsIn] = EyelinkClearBuffer(drained)    


dv.el.sampleNum     = 1;
dv.el.eventNum      = 1;
dv.el.drained       =   false; % drained is a flag for pulling from the buffer
bufferSize = str2double(dv.el.srate)*dv.el.maxTrialLength; 
dv.el.sampleBuffer  = nan(dv.el.buffersamplelength,bufferSize);
dv.el.eventBuffer   = nan(dv.el.buffereventlength,bufferSize);
dv.el.hasSamples    = true;
dv.el.hasEvents     = true;

% Pre clear buffer
if Eyelink('CheckRecording')~=0
    Eyelink('StartRecording')
end

dv.el.drained = pdsEyelinkClearBuffer(dv.el.drained);

 