function dv = spikeServerConnect(dv)
% dv = spikeServerConnect(dv)
%
% INPUTS
%       dv [struct]
%           .spikeserver [struct] - spikeserver subfield
%                   .selfip [string]   - ip address of local ethernet card
%                   .selfport[double]  - port number(same on server)
%                   .remoteip [string] - ip address of server (plexon PC)
%                   .remoteport[double]- port number (same as selfport)
% OUTPUTS
%       dv [struct]
%           .spikeserver [struct] - spikeserver subfield
%    modified fields: 
%               .sock
%               .isConnected 
%               .t0 - time of connection (server)
%               .localt0 - time of connection (local)


try
    [dv.spikeserver.sock,dv.spikeserver.isConnected, dv.spikeserver.t0, dv.spikeserver.localt0] = udpConnect(dv.spikeserver.selfip,dv.spikeserver.selfport,dv.spikeserver.remoteip,dv.spikeserver.remoteport);
    if dv.spikeserver.isConnected ==0
        disp('***********************************************************')
        disp('SPIKE SERVER FAILURE TO CONNECT')
        disp('***********************************************************')
        disp('spikeserver failed to connect to plexon PC without erroring')
        disp('try restarting spikeserver on the plexon PC and then re-run')
        disp('dv = spikeServerConnect(dv) from the command line on this rig')
        disp('if that still doesn''t work. check the ip address on both machines')
        disp('see setupPLDAPSenv.m for instructions on updating spikeserver preferences')
        pause(2)
    end
catch me
    disp('error connecting to spike server')
    dv.spikeserver.error = me; 
    dv.spikeserver.isConnected = false; 
end
