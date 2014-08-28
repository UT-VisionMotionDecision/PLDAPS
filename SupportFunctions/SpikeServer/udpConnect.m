function [sock,s, remotet0, localt0] = udpConnect(selfip,selfport,remoteip,remoteport)
% [sock,s, remotet0, localt0] = udpConnect(selfip,selfport,remoteip,remoteport)
% 
% SPIKESERVERCONNECT opens a udp connection with the plexon rig
remotet0 = 0; 
localt0  = 0; 

pnet('closeall');

sock=pnet('udpsocket',selfport);
if sock == -1
    error('Could not open port %d',selfport);
end
pnet(sock,'setwritetimeout',1);
pnet(sock,'setreadtimeout',1);

sz = pnet(sock,'readpacket');

%Send request
disp('Connecting to server');

pnet(sock,'printf',['MARCO' char(10) selfip char(10)]);
pnet(sock,'write',uint16(selfport));
pnet(sock,'writepacket',remoteip,remoteport);

sz = pnet(sock,'readpacket');
s = sz > 1;


if s
    %Awesome
    msg = pnet(sock,'readline');
    
    %Receive a polo message from the server   
    if strcmp(msg,'POLO')
        %Received acknowledgement, sync times
        disp('Connected to server');
        remotet0 = pnet(sock,'read',[1,1],'double');
        localt0 = GetSecs;
        
    end
    
end