function [dv, spikes] = getSpikes(dv)
% [dv, spikes] = spikeServerGetSpikes(dv)
%
% SPIKESERVERGETSPIKES reads spikes from the udp connection opened by
% spikeServerConnect.m
spikes = [];
if dv.trial.spikeserver.use
    [spikes, dv.trial.spikeserver.sock] = udpGetData(dv.trial.spikeserver.selfip,dv.trial.spikeserver.selfport,dv.trial.spikeserver.remoteip,dv.trial.spikeserver.remoteport,dv.trial.spikeserver.sock, dv.trial.spikeserver.t0);
end