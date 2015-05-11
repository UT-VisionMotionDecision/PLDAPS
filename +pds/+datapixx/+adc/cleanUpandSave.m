function p = cleanUpandSave(p)
%pds.datapixx.adc.prepareTrial    clean up after the trial
%
% p = pds.datapixx.adc.cleanUpandSave(p) 
%
% prunes unused preallocated dataspace.
%     jk  2015 wrote it

if ~p.trial.datapixx.use || isempty(p.trial.datapixx.adc.channels)
    return;
end

maxDataSamplesPerTrial=size(p.trial.datapixx.adc.dataSampleTimes,2);

%TODO? 1. stop recording if during trial only requested.

%prune Data structs
nMaps=length(p.trial.datapixx.adc.channelMappingChannels);
if p.trial.datapixx.adc.dataSampleCount < maxDataSamplesPerTrial/2 
    inds=1:p.trial.datapixx.adc.dataSampleCount;
        p.trial.datapixx.adc.dataSampleTimes=p.trial.datapixx.adc.dataSampleTimes(inds);
        for imap=1:nMaps

            %     iChannels=p.trial.datapixx.adc.channelMappingChannels{imap};
            iSub = p.trial.datapixx.adc.channelMappingSubs{imap};
            iSub(end).subs{2}=inds;
            iSub(end).subs{1}=':';

            p=subsasgn(p,iSub(1:end-1),subsref(p,iSub));
        end
elseif p.trial.datapixx.adc.dataSampleCount < maxDataSamplesPerTrial
    inds=p.trial.datapixx.adc.dataSampleCount+1:maxDataSamplesPerTrial;
        p.trial.datapixx.adc.dataSampleTimes(inds)=[];
        for imap=1:nMaps

            %     iChannels=p.trial.datapixx.adc.channelMappingChannels{imap};
            iSub = p.trial.datapixx.adc.channelMappingSubs{imap};
            iSub(end).subs{2}=inds;
            iSub(end).subs{1}=':';

            p=subsasgn(p,iSub,[]);
        end
end
 