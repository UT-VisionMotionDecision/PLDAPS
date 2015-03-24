function p = connect(p)
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

if ~p.trial.plexon.spikeserver.use
    fprintf('spike server is turned off. If you intend it to be on, update your rig file to include dv.useSpikeserver = 1\r')
else
    try
        [sock,isConnected,t0,localt0]=udpConnect(p.trial.plexon.spikeserver.selfip,p.trial.plexon.spikeserver.selfport,p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport);
        p.trial.plexon.spikeserver.sock=sock;
        p.trial.plexon.spikeserver.isConnected=isConnected;
        p.trial.plexon.spikeserver.t0=t0;
        p.trial.plexon.spikeserver.localt0 = localt0;
        if p.trial.plexon.spikeserver.isConnected ==0
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
        p.trial.plexon.spikeserver.error = me;
        p.trial.plexon.spikeserver.isConnected = false;
        p.trial.plexon.spikeserver.use = 0;        
    end
end
