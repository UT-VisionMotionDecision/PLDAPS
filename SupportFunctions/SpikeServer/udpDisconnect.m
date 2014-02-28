function udpDisconnect(selfip,selfport,remoteip,remoteport,sock)
% spikeServerDisconnect(selfip,selfport,remoteip,remoteport,sock)
%
% SPIKESERVERDISCONNECT disconnects spike server 



pnet(sock,'printf',['DISCONNECT' char(10) selfip char(10)]);
pnet(sock,'write',uint16(selfport));
pnet(sock,'writepacket',remoteip,remoteport);