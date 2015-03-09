function [p, spikes] = getSpikes(p)
% [dv, spikes] = spikeServerGetSpikes(dv)
%
% SPIKESERVERGETSPIKES reads spikes from the udp connection opened by
% spikeServerConnect.m
spikes = [];
if p.trial.plexon.spikeserver.use
    [spikes, sock] = udpGetData(p.trial.plexon.spikeserver.selfip,p.trial.plexon.spikeserver.selfport,p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport,p.trial.plexon.spikeserver.sock, p.trial.plexon.spikeserver.t0);
    p.trial.plexon.spikeserver.sock = sock;
end