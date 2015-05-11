function p = start(p)
%pds.datapixx.adc.prepareTrial    start continuous datapixx data aquisition
%
% p = pds.datapixx.adc.start(p) 
%
% The function starts a continuous schedule of ADC data acquisition, stored 
% on the datapixx buffer.
% Data will be read in by repeatedly (once per frame or trial) calling
% pds.datapixx.adc.getData (using Datapixx('ReadAdcBuffer')) and when
% pds.datapixx.adc.stop is called, which will also stop adc data aquesition (Datapixx('StopAdcSchedule'))
% parameters that are required by Datapixx are in the '.datapixx.adc.' fields.
% 
% INPUTS
%	p   - pldaps class
% with parameters set: 
% p.trial
%       .datapixx.useAsEyepos = false % in seconds
%       .datapixx.adc.startDelay = 0 % in seconds
%       .datapixx.adc.srate = %1000;
%       .datapixx.adc.maxSamples%=0; % infinite
%       .datapixx.adc.channels =[]
%       .datapixx.adc.XEyeposChannel =[]
%       .datapixx.adc.YEyeposChannel =[]
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
%     jk  modified 2014 new parameter structure, add flexibility, sample timing

%% build the AdcChListCode
if ~p.trial.datapixx.use || isempty(p.trial.datapixx.adc.channels)
    return;
end
AdcChListCode = zeros(2,length(p.trial.datapixx.adc.channels));
AdcChListCode(1,:)=p.trial.datapixx.adc.channels;
if ~isempty(p.trial.datapixx.adc.channelModes)
	AdcChListCode(2,:)=p.trial.datapixx.adc.channelModes; %i.e. channelMode can be a common scalar or a vector 
end

%% prepare mapping of the data
%first create the S structs for subsref.
% Got a big WTF on your face? read up on subsref, subsasgn and substruct
% we need this to dynamically access data deep inside a multilevel struct
% without using eval.
S.type='.';
S.subs='trial';

if ischar(p.trial.datapixx.adc.channelMapping)
    p.trial.datapixx.adc.channelMapping={p.trial.datapixx.adc.channelMapping};
end

if length(p.trial.datapixx.adc.channelMapping)==1
    p.trial.datapixx.adc.channelMapping=repmat(p.trial.datapixx.adc.channelMapping,[1,length(p.trial.datapixx.adc.channels)]);
end
maps=unique(p.trial.datapixx.adc.channelMapping);

p.trial.datapixx.adc.channelMappingSubs=cell(size(maps));
p.trial.datapixx.adc.channelMappingChannels=cell(size(maps));
p.trial.datapixx.adc.channelMappingChannelInds=cell(size(maps));
for imap=1:length(maps)
    p.trial.datapixx.adc.channelMappingChannelInds{imap}=strcmp(p.trial.datapixx.adc.channelMapping,maps(imap));
    p.trial.datapixx.adc.channelMappingChannels{imap}=p.trial.datapixx.adc.channels(p.trial.datapixx.adc.channelMappingChannelInds{imap});
    levels=textscan(maps{imap},'%s','delimiter','.');
    levels=levels{1};
    if maps{imap}(1)=='.'
        levels(1)=[];
    end
   
    Snew=repmat(S,[1 length(levels)]);
    [Snew.subs]=deal(levels{:});
    S2=S;
    S2.type='()';
    S2.subs={1:length(p.trial.datapixx.adc.channelMappingChannelInds{imap}), 1};
    
    p.trial.datapixx.adc.channelMappingSubs{imap}=[S Snew S2];
end

p.trial.datapixx.adc.dataSampleCount=0;

Datapixx('StopAllSchedules')
Datapixx('RegWrRd')

% set the schedule:
Datapixx('SetAdcSchedule', p.trial.datapixx.adc.startDelay, p.trial.datapixx.adc.srate, p.trial.datapixx.adc.maxSamples, AdcChListCode, p.trial.datapixx.adc.bufferAddress, p.trial.datapixx.adc.numBufferFrames);
Datapixx('DisableDacAdcLoopback');           % Replace this with DisableDacAdcLoopback to collect real data
Datapixx('DisableAdcFreeRunning');          % For microsecond-precise sample windows
Datapixx('StartAdcSchedule')
Datapixx('RegWrRd')

% timing:
p.trial.datapixx.adc.startDatapixxTime = Datapixx('GetTime'); %GetSecs;
p.trial.datapixx.adc.startPldapsTime = GetSecs;
[getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');
p.trial.datapixx.adc.startDatapixxPreciseTime(1:3) = [getsecs, boxsecs, confidence]; 
 