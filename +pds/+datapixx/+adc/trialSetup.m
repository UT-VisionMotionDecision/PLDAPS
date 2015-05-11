function p = trialSetup(p)
%pds.datapixx.adc.trialSetup    setup everything for a trial
%
% p = pds.datapixx.adc.trialSetup(p) 
% 
% The function mainly preallocates data for the trial
% 
%     jk  wrote it 2014

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
maxDataSamplesPerTrial=p.trial.datapixx.adc.srate*60*10;
nMaps=length(p.trial.datapixx.adc.channelMappingChannels);
for imap=1:nMaps
%     iChannels=p.trial.datapixx.adc.channelMappingChannels{imap};
    iSub = p.trial.datapixx.adc.channelMappingSubs{imap};
       
    %always reassign, because that's what happening at the first write
    %anyways.
    p=subsasgn(p,iSub(1:end-1),nan(length(p.trial.datapixx.adc.channelMappingChannels{imap}), maxDataSamplesPerTrial));
end
p.trial.datapixx.adc.dataSampleTimes=nan(1,maxDataSamplesPerTrial);

% 3. reset the counter.
p.trial.datapixx.adc.dataSampleCount=0;