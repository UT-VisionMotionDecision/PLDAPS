function dp = datapixxAdcStart(dp)
% function [dp] = DatapixxAdcStart(dp)
% 
% The function starts a continuous schedule of ADC data acquisition, stored 
% on the datapixx buffer. It will continue until a 
% Datapixx('StopAdcSchedule') will be encountered, upon which it may be
% read by using Datapixx('ReadAdcBuffer'). (* AdcStop does exactly that.)
% parameters that are required by Datapixx are in the 'dp' struct.
% 
% INPUTS
%	dp   - struct
%           .srate - samplingrate
%           .maxFr - max Frames
%   .AdcChListCode - Channels to use
%         .nBuffFr - number frames in the buffer
% (c) lnk 2012
%     jly modified 2013
Datapixx('StopAllSchedules')

% set the schedule:
Datapixx('SetAdcSchedule', 0, dp.srate, dp.maxFr, dp.AdcChListCode, 0, dp.nBuffFr);
Datapixx('StartAdcSchedule')
Datapixx('RegWrRd')

% timing:
dp.adctstart = Datapixx('GetTime'); %GetSecs;



%% appendix - Datapixx ADC commands:
% 
% ADC (Analog to Digital Converter) subsystem:
%
% adcNumChannels = Datapixx('GetAdcNumChannels');
% adcRanges      = Datapixx('GetAdcRanges');
% adcVoltages    = Datapixx('GetAdcVoltages');
% Datapixx('EnableDacAdcLoopback');
% Datapixx('DisableDacAdcLoopback');
% Datapixx('EnableAdcFreeRunning');
% Datapixx('DisableAdcFreeRunning');
% Datapixx('SetAdcSchedule', scheduleOnset, scheduleRate, maxScheduleFrames [, channelList=0] [, bufferBaseAddress=4e6] [, numBufferFrames=maxScheduleFrames]);
% Datapixx('StartAdcSchedule');
% Datapixx('StopAdcSchedule');
% [bufferData, bufferTimetags, underflow, overflow] = Datapixx('ReadAdcBuffer', numFrames [, bufferAddress]);
% status = Datapixx('GetAdcStatus');
% 

 