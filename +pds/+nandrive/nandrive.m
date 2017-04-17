function p = nandrive(p,state,sn)
%how to use
% load pldaps:
% e.g. p=pldaps;
% add nandrive, e.g. tell to have settings in field 'nan'
% p=pds.nandrive.nandrive(p,-Inf, 'nan');
    if nargin<3
        sn='nandrive';
    end
    
    switch state
        %connect
         case -Inf
            if (isa(p.trial,'params') && ~isField(p.trial, sn)) || ~isfield(p.trial, sn)
                 p.trial.(sn) = struct;
            end
            if ~isfield(p.trial.(sn), 'selfip') || isempty(p.trial.(sn).selfip)
                address = java.net.InetAddress.getLocalHost;
                p.trial.(sn).selfip = char(address.getHostAddress);
            end
            if ~isfield(p.trial.(sn), 'selfport')
                p.trial.(sn).selfport = 5332;
            end
            if ~isfield(p.trial.(sn), 'remoteip')
                p.trial.(sn).remoteip = 'xx.xx.xx.xx';
            end
            if ~isfield(p.trial.(sn), 'remoteport')
                p.trial.(sn).remoteport = 5333;
            end
            if ~isfield(p.trial.(sn), 'use')
                p.trial.(sn).use = true;
            end
            if ~isfield(p.trial.(sn), 'stateFunction') || ~isfield(p.trial.(sn).stateFunction,'name')
                p.trial.(sn).stateFunction.name = 'pds.nandrive.nandrive';
            end
            
            if  ~isfield(p.trial.(sn).stateFunction,'acceptsLocationInput')
                p.trial.(sn).stateFunction.acceptsLocationInput=true;
            end
            
            if ~isfield(p.trial.(sn).stateFunction,'order')
                p.trial.(sn).stateFunction.order = 0;
            end
            if ~isfield(p.trial.(sn).stateFunction,'requestedStates') || ~isfield(p.trial.(sn).stateFunction.requestedStates,'trialSetup')
                p.trial.(sn).stateFunction.requestedStates.trialSetup = true;
            end
            if ~isfield(p.trial.(sn).stateFunction.requestedStates,'trialCleanUpandSave')
                p.trial.(sn).stateFunction.requestedStates.trialCleanUpandSave = true;
            end
            if ~isfield(p.trial.(sn).stateFunction.requestedStates,'experimentPostOpenScreen')
                p.trial.(sn).stateFunction.requestedStates.experimentPostOpenScreen = true;
            end
            if ~isfield(p.trial.(sn).stateFunction.requestedStates,'experimentCleanUp')
                p.trial.(sn).stateFunction.requestedStates.experimentCleanUp = true;
            end      
        case p.trial.pldaps.trialStates.experimentPostOpenScreen
            try
%                 [sock,isConnected,t0,localt0]=udpConnect(p.trial.(sn).selfip,p.trial.(sn).selfport,p.trial.(sn).remoteip,p.trial.(sn).remoteport);
                remotet0 = 0; 
                localt0  = 0; 
                isConnected=false;
                
                %connect to port. free, if possible, if already in use
                sock=pnet('udpsocket',p.trial.(sn).selfport);
                if sock == -1
                    try
                        cons=pnet('getAll');
                        iCon=find([cons.port]==p.trial.(sn).selfport);
                        if ~isempty(iCon)
                            fprintf('Port %i was already in use by pnet. Taking it over.\n', p.trial.(sn).selfport);
                            pnet(cons(iCon).socket,'close');
                            sock=pnet('udpsocket',p.trial.(sn).selfport);
                        end
                    catch
                        sock = -1;
                    end
                    if sock == -1
                        pnet('closeall');
                        error('Could not open port %d',p.trial.(sn).selfport);
                    end
                end
                p.trial.(sn).sock=sock;
                
                pnet(sock,'setwritetimeout',1);
                pnet(sock,'setreadtimeout',1);
                sz = pnet(sock,'readpacket');
                %Send request
                disp('Connecting to server');
                pnet(sock,'printf',['MARCO' char(10) p.trial.(sn).selfip char(10)]);
                pnet(sock,'write',uint16(p.trial.(sn).selfport));
                pnet(sock,'writepacket',p.trial.(sn).remoteip,p.trial.(sn).remoteport);
                sz = pnet(p.trial.(sn).sock,'readpacket');
                s = sz > 1;
                if s
                    %Awesome
                    msg = pnet(p.trial.(sn).sock,'readline');
                    %Receive a polo message from the server   
                    if strcmp(msg,'POLO')
                        %Received acknowledgement, sync times
                        disp('Connected to nan server');
                        remotet0 = pnet(p.trial.(sn).sock,'read',[1,1],'double');
                        localt0 = GetSecs;
                        isConnected=true;
                    end
                end

               
                p.trial.(sn).isConnected=isConnected;
                p.trial.(sn).t0=remotet0;
                p.trial.(sn).localt0 = localt0;


                if p.trial.(sn).isConnected ==0
                    disp('***********************************************************')
                    disp('NAN DRIVE POSITION SERVER FAILURE TO CONNECT')
                    disp('***********************************************************')
                    disp('failed to connect to nandrive control PC without erroring')
                    disp('try restarting the server on the nandrive PC and then re-run')
                    disp('pds.nandrive.nandrive(p,p.trial.pldaps.trialStates.experimentPostOpenScreen, NANDRIVESETTINGSLOCATION) from the command line on this rig')
                    disp('if that still doesn''t work. check the ip address on both machines')
                    pause(2)
                end
            catch me
                disp('error connecting to spike server')
                p.trial.(sn).error = me;
                p.trial.(sn).isConnected = false;
                p.trial.(sn).use = 0;        
            end
        case p.trial.pldaps.trialStates.experimentCleanUp
            if p.trial.(sn).use && isfield(p.trial.(sn), 'sock')
                pnet(p.trial.(sn).sock,'printf',['DISCONNECT' char(10) p.trial.(sn).selfip char(10)]);
                pnet(p.trial.(sn).sock,'write',uint16(p.trial.(sn).selfport));
                pnet(p.trial.(sn).sock,'writepacket',p.trial.(sn).remoteip,p.trial.(sn).remoteport);
                pnet(p.trial.(sn).sock,'close');
                p.trial.(sn).isConnected = 0;
            end
        %request to get current position
        case p.trial.pldaps.trialStates.trialSetup
            pnet(p.trial.(sn).sock,'printf',['GETNANPOSITIONS' char(10) p.trial.(sn).selfip char(10)]);
            pnet(p.trial.(sn).sock,'write',uint16(p.trial.(sn).selfport));
            pnet(p.trial.(sn).sock,'writepacket',p.trial.(sn).remoteip,p.trial.(sn).remoteport);

            %create field to hold the data
            p.trial.(sn).positions = ones(0,3);
        %read the nanpositions that got send
        case p.trial.pldaps.trialStates.trialCleanUpandSave
            %Receive messages
            sze = pnet(p.trial.(sn).sock,'readpacket', 2000000, 'noblock');
            if sze > 0
                msg = pnet(p.trial.(sn).sock,'readline');
                if strcmp(msg,'NANPOSITIONS')
                    nantime=pnet(p.trial.(sn).sock,'read',[1,1],'double');

                    currentlength= size(p.trial.(sn).positions,1);
                    data=pnet(p.trial.(sn).sock,'read',[1,2],'double');
                    while data
                        p.trial.(sn).positions(end+1,2:3)=data;
                        data=pnet(p.trial.(sn).sock,'read',[1,2],'double');
                    end
                    p.trial.(sn).positions(currentlength+1:end,1)=nantime;
                else
                    fprintf('Invalid message type received: %s\n',msg);
                    return
                end
            end
        %default parameters    
    end %switch state
end