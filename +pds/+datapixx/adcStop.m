 function dp = adcStop(dp)
% [dp] = pds.datapixx.adcStop(dp)
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

Datapixx RegWrRd;
% timing:
dp.adctend    = Datapixx('GetTime'); %GetSecs;
dp.timewindow = dp.adctend-dp.adctstart; % (seconds)

% number of buffer frames to be read:
nBufferFrames = ceil(dp.timewindow * dp.srate);

Datapixx('StopAdcSchedule')
dp.bufferData = Datapixx('ReadAdcBuffer', nBufferFrames);


% % % setting up the time axis to fit the num of elements in buffer data:
% % if size(1:dp.sstep:dp.timewindow*1000, 2) == size(dp.bufferData, 2)
% %     dp.timeaxis = 1:dp.sstep:dp.timewindow*1000;
% % else
% %     dp.timeaxis = 1:dp.sstep:dp.timewindow*1000+1;
% % end
