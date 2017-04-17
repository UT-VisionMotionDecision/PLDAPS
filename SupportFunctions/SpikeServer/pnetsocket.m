classdef pnetsocket < handle
	properties
        sock
        port = [];
        clientip
        clientport
        isOpen=false;
        
        splice_pause=0.010;
        port_q=0.010;
        maxpacketsize = 2e3;
        timeout = 1500;
        
        readtimeout=.002;
        writetimeout=1;
        clientisconnected = 0;
        connecttime = NaN;
        
        instruction='';
    end
   
    methods 
       function s = open(s,port) 
            if(s.isOpen)
                s=close(s);
            end
            s.port=port;
            %Listen for an incoming connection on port #
            s.sock=pnet('udpsocket',s.port);

            if s.sock == -1 %port is blocked, check if it's blocked by us
                try
                    cons=pnet('getAll');
                    iCon=find([cons.port]==s.port);
                    if ~isempty(iCon)
                        fprintf('Port %s was already in use by pnet. Taking it over.\n', s.port);
                        pnet(cons(iCon).socket,'close');
                        s.sock=pnet('udpsocket',s.port);
                    end
                catch
                    s.sock = -1;
                end
                if s.sock == -1
                    error('Port %d is blocked',s.port);
                end
            end
             %Only wait for 100 ms before giving up
            pnet(s.sock,'setreadtimeout',s.readtimeout);
            pnet(s.sock,'setwritetimeout',s.writetimeout);
            
            s.clientisconnected = 0;
            s.connecttime = clock + 1;
            s.isOpen=true;
       end
       
       function s = close(s) 
           pnet(s.sock, 'close');
           s.isOpen=false;
           s.clientisconnected = 0;
           s.connecttime = clock + 1;
       end
       
       function s=readAndReply(s)
            WaitSecs(s.splice_pause*2);
            
            msglen = pnet(s.sock,'readpacket');
            if msglen == 0
                s.instruction = '';
            else
                %Read instruction
                s.instruction = pnet(s.sock,'readline');
                fprintf('Received message from client... %s\n',s.instruction);
                switch s.instruction
                    case 'MARCO'
                        if s.clientisconnected
                            fprintf('Client was already previously connected.');
                        end
                        %Handshake request
                        %Read IP
                        s.clientip = pnet(s.sock,'readline');
                        s.clientport = pnet(s.sock,'read',[1,1],'uint16');

                        currenttime = GetSecs;
                        %connect to client and send a payload containing 
                        %the current time on the server
                        pnet(s.sock,'printf',['POLO' char(10)]);
                        pnet(s.sock,'write',currenttime);
                        pnet(s.sock,'writepacket',s.clientip,double(s.clientport));

                        fprintf('Client %s:%d connected\n',s.clientip,s.clientport);

                        s.clientisconnected = 1;

                        s.connecttime = clock;
                    case 'KEEPALIVE'
                        if s.clientisconnected 
                            s.connecttime = clock;
                        end
                    case 'DISCONNECT'
                        s=close(s);
                        s=open(s,s.port);
                    otherwise
                        if s.clientisconnected 
                            s.connecttime = clock;
                        end
                end
            end
            %disconect after timeout
            if etime(clock,s.connecttime) > s.timeout
                disp('client disconnected. Wait for reconnection');
                %close port
                s = close(s);
                s = open(s,s.port);
            end
        end
    end
end