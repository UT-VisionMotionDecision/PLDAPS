 function p = stop(p)
% [dp] = pds.datapixx.adc.stop(dp)
% 
% The function should be called after AdcStart.
% * AdcStart STARTS a continuous schedule of ADC data acquisition, stored 
%   on the datapixx buffer. 
% * AdcStop STOPS the recording and outputs the buffered data.
% 
% parameters that are required by Datapixx are in the 'dp' struct.
% INPUTS 
%   dp - struct
%    .srate - sampling rate
%
% ??/2012    lnk    Wrote it
% 12/12/2013 jly    Renamed to pdsDatapixxAdcStop 

%TODO: why are the buffertimetags (second output of 'ReadAdcbuffer' not
%saved??
%according to the help, one should also use
%Datapixx('GetAdcStatus').newBufferFrames to determine the actual number of
%samples.
if ~p.trial.datapixx.use || isempty(p.trial.datapixx.adc.channels)
    return;
end

p = pds.datapixx.adc.getData(p);

Datapixx RegWrRd;
Datapixx('StopAdcSchedule')

% timing:
p.trial.datapixx.adc.stopDatapixxTime = Datapixx('GetTime'); %GetSecs;
p.trial.datapixx.adc.stopPldapsTime = GetSecs;
[getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');
p.trial.datapixx.adc.stopDatapixxPreciseTime(1:3) = [getsecs, boxsecs, confidence];
