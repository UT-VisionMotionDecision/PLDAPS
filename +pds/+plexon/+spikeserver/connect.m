function p = connect(p)
%pds.plexon.spikeserver.connect   connect to a remote plexon spikeserver
%
% connects to the spikeserver and requests to get the file currently
% recorded to.
%
% p = pds.plexon.spikeserver.connect(p)
%

%  Lets not do this
        % if ~p.trial.plexon.spikeserver.use
        %     fprintf('spike server is turned off. If you intend it to be on, update your rig file to include dv.useSpikeserver = 1\r')
        % else
if p.trial.plexon.spikeserver.use

    fprintLineBreak
    fprintf('\tInitializing Plexon spikeserver.\n');
    fprintLineBreak
    
    try
        if isempty(p.trial.plexon.spikeserver.selfip)
            address = java.net.InetAddress.getLocalHost;
            p.trial.plexon.spikeserver.selfip = char(address.getHostAddress);
        end
        
        [sock,isConnected,t0,localt0]=udpConnect(p.trial.plexon.spikeserver.selfip,p.trial.plexon.spikeserver.selfport,p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport);
        p.trial.plexon.spikeserver.sock=sock;
        p.trial.plexon.spikeserver.isConnected=isConnected;
        p.trial.plexon.spikeserver.t0=t0;
        p.trial.plexon.spikeserver.localt0 = localt0;
        
        %set settings:
        pnet(sock,'printf',['SETTINGS' char(10)]);% p.trial.plexon.spikeserver.selfip char(10)]);
        pnet(sock,'printf',['EVENTSONLY' char(10)]);
        pnet(sock,'write',uint8(p.trial.plexon.spikeserver.eventsonly));
        pnet(sock,'writepacket',p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport);
        
        pnet(sock,'printf',['SETTINGS' char(10)]);% p.trial.plexon.spikeserver.selfip char(10)]);
        pnet(sock,'printf',['CONTINUOUS' char(10)]);
        pnet(sock,'write',uint8(p.trial.plexon.spikeserver.continuous));
        pnet(sock,'writepacket',p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport);
        
        %get filename
        pnet(sock,'printf',['GETFILENAME' char(10)]);
        pnet(sock,'writepacket',p.trial.plexon.spikeserver.remoteip,p.trial.plexon.spikeserver.remoteport);
        
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
