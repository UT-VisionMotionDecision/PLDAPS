function dv = spikeserverConnect(dv)
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

if ~dv.trial.spikeserver.use
    fprintf('spike server is turned off. If you intend it to be on, update your rig file to include dv.useSpikeserver = 1\r')
else
    try
        [dv.trial.spikeserver.sock,dv.trial.spikeserver.isConnected, dv.trial.spikeserver.t0, dv.trial.spikeserver.localt0] = udpConnect(dv.trial.spikeserver.selfip,dv.trial.spikeserver.selfport,dv.trial.spikeserver.remoteip,dv.trial.spikeserver.remoteport);
        if dv.trial.spikeserver.isConnected ==0
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
        dv.trial.spikeserver.error = me;
        dv.trial.spikeserver.isConnected = false;
        dv.trial.spikeserver.use = 0;        
    end
end
