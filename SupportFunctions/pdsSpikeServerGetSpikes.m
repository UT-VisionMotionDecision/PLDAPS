function [dv, spikes] = spikeServerGetSpikes(dv)
% [dv, spikes] = spikeServerGetSpikes(dv)
%
% SPIKESERVERGETSPIKES reads spikes from the udp connection opened by
% spikeServerConnect.m
spikes = [];
if isfield(dv, 'spikeserver')
    [spikes, dv.spikeserver.sock] = udpGetData(dv.spikeserver.selfip,dv.spikeserver.selfport,dv.spikeserver.remoteip,dv.spikeserver.remoteport,dv.spikeserver.sock, dv.spikeserver.t0);
end