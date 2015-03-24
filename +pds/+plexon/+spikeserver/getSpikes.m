function [p, spikes] = getSpikes(p)
% [dv, spikes] = spikeServerGetSpikes(dv)
%
% SPIKESERVERGETSPIKES reads spikes from the udp connection opened by
% spikeServerConnect.m
spikes = [];
if p.trial.plexon.spikeserver.use
    [spikes, sock] = udpGetData(p.trial.plexon.spikeserver.selfip,p.trial.plexon.spikeserver.selfport,p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport,p.trial.plexon.spikeserver.sock, p.trial.plexon.spikeserver.t0);
    p.trial.plexon.spikeserver.sock = sock;
    
    if ~isempty(spikes)
        p.trial.plexon.spikeserver.spikes(p.trial.plexon.spikeserver.spikeCount+1:p.trial.plexon.spikeserver.spikeCount+size(spikes,1),:)=spikes;
        p.trial.plexon.spikeserver.spikeCount=p.trial.plexon.spikeserver.spikeCount+size(spikes,1);
    end
end