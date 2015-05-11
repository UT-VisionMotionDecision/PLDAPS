function [spikes, sock, other] = udpGetData(selfip,selfport,remoteip,remoteport,sock, t0)
% spikes = pds.spikeserver.udpGetData(selfip,selfport,remoteip,remoteport)
%
% SPIKESERVERGETSPIKES reads spikes from the udp connection opened by
% pds.spikeserver.connect.m
spikes = [];
other.filename=[];
other.nanpositions=[];
% initt0 = GetSecs;

pnet(sock,'printf',['GET' char(10) selfip char(10)]);
pnet(sock,'write',uint16(selfport));
pnet(sock,'writepacket',remoteip,remoteport);

% pnet(sock,'printf',['GETNANPOSITIONS' char(10) selfip char(10)]);
% pnet(sock,'write',uint16(selfport));
% pnet(sock,'writepacket',remoteip,remoteport);

% remotet0 = pnet(sock,'read',[1,1],'double');

%Receive messages
sze = pnet(sock,'readpacket', 2000000, 'noblock');
% localt0 = GetSecs - initt0;

if sze > 0
    msg = pnet(sock,'readline');
    if strcmp(msg,'SPIKES')
        %Read spikes
        packetNr=pnet(sock,'read',[1,1],'double');
        sze = sze - 7 - 8;
        nspks = sze/(8*4);
        if nspks ~= 0 %No spikes in this one
            data = pnet(sock,'read',[nspks,4],'double');
            if isempty(data)
                disp('Corrupt message received');
                return
            end
            data(:,4) = data(:,4); % - remotet0 + localt0;
            data(:,5)=packetNr;
            spikes = [spikes;data];
        end
    elseif strcmp(msg,'FILENAME')
        other.filename=pnet(sock,'readline');
    elseif strcmp(msg,'NANPOSITIONS')
        nantime=pnet(sock,'read',[1,1],'double');
        
        currentlength= size(other.nanpositions,1);
        %other.nan.positions=zeros(0,2);
        data=pnet(sock,'read',[1,2],'double');
        while data
            other.nanpositions(end+1,2:3)=data;
        end
        other.nanpositions(currentlength+1:end,1)=nantime;
    else
        fprintf('Invalid message type received: %s\n',msg);
        return
    end
    
else
%     disp('Timeout receiving spikes');
    return
end


% % dnow = GetSecs - initt0;
% % if mod(dbefore,2) > mod(dnow,2)
% %     %Send keep alive signal every 10 seconds
% %     pnet(sock,'printf',['KEEPALIVE' char(10) selfip char(10)]);
% %     pnet(sock,'write',int16(selfport));
% %     pnet(sock,'writepacket',remoteip,remoteport);
% % end
% % 
% % %                 if mod(dbefore,3) > mod(dnow,3)
% % %                     %Plot the spikes in the last 5 seconds
% % %                     tgt = spikes(spikes(:,3) - dnow + 1 > 0,:);
% % %                     plot(tgt(:,3) - dnow + 1,tgt(:,1) + (tgt(:,2)-1)*128,'.');
% % %                     drawnow;
% % %                     spikes = [];
% % %                 end
% % %
% % dbefore = dnow;
% % else
% %     %timed out... either no spikes for a second or some network issue
% %     %Try reconnecting
% %     disp('Timeout receiving spikes');
% %     break;
% % end
% % end




