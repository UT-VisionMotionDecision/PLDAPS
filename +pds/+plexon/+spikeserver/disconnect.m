function p = disconnect(p)
%pds.plexon.spikeserver.disconnect   disconnects the remote plexon spikeserver
%
% p = pds.plexon.spikeserver.disconnect(p)
%


if p.trial.plexon.spikeserver.use && isfield(p.trial.plexon.spikeserver, 'sock')
    pnet(p.trial.plexon.spikeserver.sock,'printf',['DISCONNECT' char(10) p.trial.plexon.spikeserver.selfip char(10)]);
    pnet(p.trial.plexon.spikeserver.sock,'write',uint16(p.trial.plexon.spikeserver.selfport));
    pnet(p.trial.plexon.spikeserver.sock,'writepacket',p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport);
    p.trial.plexon.spikeserver.isConnected = 0;
    pnet(p.trial.plexon.spikeserver.sock,'close');
end