 function p = stop(p)
% stops datapixx data aquisition
% [p] = PDS.DATAPIXX.ADC.STOP(p)
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
%   See also PDS.DATAPIXX.ADC.START, STD, MIN, MAX, VAR, COV, MODE.
% Typically called during cleanUpandSave
%       pldapsDefaultTrialFunction(p, p.trial.pldaps.trialStates.trialCleanUpandSave)
%
%   See also PDS.DATAPIXX.ADC.START, STD, MIN, MAX, VAR, COV, MODE.

%TODO: why are the buffertimetags (second output of 'ReadAdcbuffer' not
%saved??
%according to the help, one should also use
%Datapixx('GetAdcStatus').newBufferFrames to determine the actual number of
%samples.
if ~p.trial.datapixx.use || isempty(p.trial.datapixx.adc.channels)
    return;
end

p = pds.datapixx.adc.getData(p);

Datapixx('StopAdcSchedule')
Datapixx RegWrRd;

% timing:
p.trial.datapixx.adc.stopDatapixxTime = Datapixx('GetTime'); %GetSecs;
p.trial.datapixx.adc.stopPldapsTime = GetSecs;
[getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');
p.trial.datapixx.adc.stopDatapixxPreciseTime(1:3) = [getsecs, boxsecs, confidence];
