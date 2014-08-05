function p = getData(p)
% function [p] = pds.datapixx.adc.getData(p)
% 
% The function collects all Data that has been recorded on the Datapixx since the last call or sind pds.datapixx.adc.start has been called.
% Parameters that are required by Datapixx are in the '.datapixx.adc.' fields.
%
% 
% INPUTS
%	p   - pldaps class
% with parameters set:        
% %       .datapixx.adc.startDelay = 0 % in seconds
% %       .datapixx.adc.srate = %1000;
% %       .datapixx.adc.maxSamples%=0; % infinite
% %       .datapixx.adc.channels =[]
% %       .datapixx.adc.channelModes =[] %see Datapixx help, 0:single ended, 1:diff to nr+1, 2: diff to Ref0, 3: diff to Ref1, default to 0.
% %       .datapixx.adc.bufferAddress;%=[];
% %       .datapixx.adc.numBufferFrames;% .datapixx.adc.srate*60*10 = 10 minutes
%       .datapixx.adc.channelGains
%       .datapixx.adc.channelOffsets
%       .datapixx.adc.channelOffsets
%       .datapixx.adc.channelMapping = 'datapixx.adc.data' cell array with targets in the trial

%       struct where this should get mapped to
% (c) lnk 2012
%     jly modified 2013
%     jk  modified to use new parameter structure

%% build the AdcChListCode
if ~p.trial.datapixx.use || isempty(p.trial.datapixx.adc.channels)
    return;
end

%consifer having a preallocated bufferData and bufferTimeTags
Datapixx('RegWrRd');
adcStatus = Datapixx('GetAdcStatus');
% adcStatus.time=GetSecs;
% p.trial.datapixx.adc.stat(end+1)=adcStatus;
[bufferData, bufferTimetags, underflow, overflow] = Datapixx('ReadAdcBuffer', adcStatus.newBufferFrames,-1);
% [bufferData, bufferTimetags, underflow, overflow] = Datapixx('ReadAdcBuffer', adcStatus.newBufferFrames,-1);
if underflow
    warning('pds:datapixxadcgetData','underflow: getData is called to often');
end
if overflow
    warning('pds:datapixxadcgetData','overflow: getData was not called often enough. Some data is lost.');
end

%transform data:
bufferData=diag(p.trial.datapixx.adc.channelGains)*(bufferData+diag(p.trial.datapixx.adc.channelOffsets)*ones(size(bufferData)));

% p.trial.datapixx.adc.dataSampleCount;
%ohoh, this will be reset every trial.
starti=p.trial.datapixx.adc.dataSampleCount+1;
endi=p.trial.datapixx.adc.dataSampleCount+adcStatus.newBufferFrames;
inds=starti:endi;
p.trial.datapixx.adc.dataSampleCount=endi;

p.trial.datapixx.adc.dataSampleTimes(inds)=bufferTimetags;
% p.trial.datapixx.adc.data(:,inds)=bufferData;

nMaps=length(p.trial.datapixx.adc.channelMappingChannels);
for imap=1:nMaps
%     iChannels=p.trial.datapixx.adc.channelMappingChannels{imap};
    iSub = p.trial.datapixx.adc.channelMappingSubs{imap};
    iSub(end).subs{2}=inds;
    
    p=subsasgn(p,iSub,bufferData(p.trial.datapixx.adc.channelMappingChannelInds{imap},:));
    
    if p.trial.datapixx.useAsEyepos
        xChannel=p.trial.datapixx.adc.XEyeposChannel==p.trial.datapixx.adc.channelMappingChannels;
        yChannel=p.trial.datapixx.adc.YEyeposChannel==p.trial.datapixx.adc.channelMappingChannels;
        if any(xChannel)
        	iSub(end).subs{1}=xChannel;
            if p.trial.pldaps.eyeposMovAv>1
                dInds=(p.trial.datapixx.adc.dataSampleCount-p.trial.pldaps.eyeposMovAv+1):p.trial.datapixx.adc.dataSampleCount;
                iSub(end).subs{2}=dInds;
                p.trial.eyeX = mean(subsref(p,iSub));
            else
                dInds=p.trial.datapixx.adc.dataSampleCount;
                iSub(end).subs{2}=dInds;
                p.trial.eyeX = subsref(p,iSub);
            end
             
        elseif any(yChannel)
            iSub(end).subs{1}=yChannel;
            
            if p.trial.pldaps.eyeposMovAv>1
                dInds=(p.trial.datapixx.adc.dataSampleCount-p.trial.pldaps.eyeposMovAv+1):p.trial.datapixx.adc.dataSampleCount;
                iSub(end).subs{2}=dInds;
                p.trial.eyeX = mean(subsref(p,iSub));
            else
                dInds=p.trial.datapixx.adc.dataSampleCount;
                iSub(end).subs{2}=dInds;
                p.trial.eyeX = subsref(p,iSub);
            end
        end
    end  
end
