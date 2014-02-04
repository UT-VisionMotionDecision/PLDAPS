function pdsSpikeServerDisconnect(dv)
% spikeServerDisconnect(dv)
%
% SPIKESERVERDISCONNECT disconnects spike server 


if dv.useSpikeServer && isfield(dv.spikeserver, 'sock')
    pnet(dv.spikeserver.sock,'printf',['DISCONNECT' char(10) dv.spikeserver.selfip char(10)]);
    pnet(dv.spikeserver.sock,'write',uint16(dv.spikeserver.selfport));
    pnet(dv.spikeserver.sock,'writepacket',dv.spikeserver.remoteip,dv.spikeserver.remoteport);
end