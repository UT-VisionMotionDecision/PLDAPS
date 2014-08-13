function p = trialSetup(p)
% function [p] = pds.datapixx.adc.prepareTrial(p)
% 
% The function starts a continuous schedule of ADC data acquisition, stored 
% on the datapixx buffer. It will continue until a 
% Data will be read in by repeatedly (one per frame or trial) calling
% pds.datapixx.adc.getData (using Datapixx('ReadAdcBuffer')) and when
% pds.datapixx.adc.stop is called, which will also stop adc data aquesition (Datapixx('StopAdcSchedule'))
% parameters that are required by Datapixx are in the '.datapixx.adc.' fields.
%
% 
% INPUTS
%	p   - pldaps class
% with parameters set:        
%       .datapixx.adc.startDelay = 0 % in seconds
%       .datapixx.adc.srate = %1000;
%       .datapixx.adc.maxSamples%=0; % infinite
%       .datapixx.adc.channels =[]
%       .datapixx.adc.channelModes =[] %see Datapixx help, 0:single ended, 1:diff to nr+1, 2: diff to Ref0, 3: diff to Ref1, default to 0.
%       .datapixx.adc.bufferAddress;%=[];
%       .datapixx.adc.numBufferFrames;% .datapixx.adc.srate*60*10 = 10 minutes
%       .datapixx.adc.channelGains
%       .datapixx.adc.channelOffsets
%       .datapixx.adc.channelOffsets
%       .datapixx.adc.channelMapping = 'datapixx.adc.data' cell array with targets in the trial
%       .datapixx.adc.channelSampleCountMapping cell array with targets in the trial
%       struct where this should get mapped to
% (c) lnk 2012
%     jly modified 2013
%     jk  modified to use new parameter structure

if ~p.trial.datapixx.use || isempty(p.trial.datapixx.adc.channels)
    return;
end

%1. check if ADC has been started, call start if not and assume trial by trial mode
Datapixx('RegWrRd');
adcStatus = Datapixx('GetAdcStatus');
if ~adcStatus.scheduleRunning
    pds.datapixx.adc.start(p);
end


% 2. check if the structs for the data exist, create if not (is that possible)
maxDataSamplesPerTrial=p.trial.datapixx.adc.srate*60*60;
nMaps=length(p.trial.datapixx.adc.channelMappingChannels);
for imap=1:nMaps
%     iChannels=p.trial.datapixx.adc.channelMappingChannels{imap};
    iSub = p.trial.datapixx.adc.channelMappingSubs{imap};
       
    %always reassign, because that's what happening at the first write
    %anyways.
    p=subsasgn(p,iSub(1:end-1),nan(length(p.trial.datapixx.adc.channelMappingChannels{imap}), maxDataSamplesPerTrial));

end
p.trial.datapixx.adc.dataSampleTimes=nan(1,maxDataSamplesPerTrial);

%create a tmp buffer for the collected data
p.trial.datapixx.adc.bufferData=nan(length(p.trial.datapixx.adc.channels),p.trial.datapixx.adc.numBufferFrames);
p.trial.datapixx.adc.bufferTimetags=nan(1,p.trial.datapixx.adc.numBufferFrames);

% 3. reset the counter.
p.trial.datapixx.adc.dataSampleCount=0;

%debug
% adcStatus.time=GetSecs;
% p.trial.datapixx.adc.stat(1)=adcStatus;
