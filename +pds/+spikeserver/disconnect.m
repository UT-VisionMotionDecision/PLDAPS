function dv = spikeserverDisconnect(dv)
% spikeServerDisconnect(dv)
%
% SPIKESERVERDISCONNECT disconnects spike server 


if dv.trial.spikeserver.use && isfield(dv.trial.spikeserver, 'sock')
    pnet(dv.trial.spikeserver.sock,'printf',['DISCONNECT' char(10) dv.trial.spikeserver.selfip char(10)]);
    pnet(dv.trial.spikeserver.sock,'write',uint16(dv.trial.spikeserver.selfport));
    pnet(dv.trial.spikeserver.sock,'writepacket',dv.trial.spikeserver.remoteip,dv.trial.spikeserver.remoteport);
    dv.trial.spikeserver.isConnected = 0;
end