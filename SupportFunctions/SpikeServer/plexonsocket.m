classdef plexonsocket < pnetsocket
	properties
      plx = 0
      packetnum = 0
      eventsonly = false
      continuous = false
      baseDir='D:\PlexonData\'
      spikes = ones(10000000,4)
      iSpikes = 0
      nSpikes = 10000000
    end
   
    methods 
        function s = plexonsocket() 
            s = s@pnetsocket();
        end

        function delete(s)
            if s.plx ~= 0
                PL_Close(s.plx);
                s.plx =0;
            end
        end

        function s = open(s,port) 
            s.packetnum=1;
            s = open@pnetsocket(s,port);
        end
        
        function s = close(s)
            s = close@pnetsocket(s);
            
            if s.plx ~= 0
                PL_Close(s.plx);
                s.plx =0;
            end 
        end
       
        function s=readAndReply(s)
                s=readAndReply@pnetsocket(s);
                if s.plx~=0
                   %getSPikes 
                   [nspks,ts] = PL_GetTS(s.plx);
                   if s.eventsonly
                   	   ts(ts(:,1) == 1,:)=[];
                   	   nspks=size(ts,1);
                   end
                   %drop spikes if buffer is full
                   if s.iSpikes + nspks > s.nSpikes
                       fprintf('Buffer running full. dropped %i spikes',s.iSpikes);
                       s.iSpikes=0;
                   end
                   if nspks > 0 && nspks < s.nSpikes
                       s.spikes(s.iSpikes+(1:nspks),:) = ts;
                       s.iSpikes = s.iSpikes + nspks;
                   end
                end
                switch s.instruction
                    case 'MARCO'
                        if s.plx == 0   
                            s.plx = PL_InitClient(0);
                            if s.plx == 0
                                error('Could not connect to Plexon server');
                            else
                                PL_WaitForServer(s.plx,100);
                            end
                        end
                        %Flush spike buffer
                        s.iSpikes=0;
                    case 'GET'
                        s = sentSpikes(s);
                    case 'SETTINGS'
                        settingInstruction = pnet(s.sock,'readline');
                        switch settingInstruction
                            case 'EVENTSONLY'
                                s.eventsonly = pnet(s.sock,'read',[1,1],'uint8');
                            case 'CONTINUOUS'
                                s.continuous = pnet(s.sock,'read',[1,1],'uint8');
                        end
                    case 'GETFILENAME'
                        a=dir([s.baseDir '*.pl*']);
                        %N=datenum({a.date});
                        [~,ii]=max([a.datenum]);
                        %a(ii).name

                        filename=[strrep(s.baseDir,'\','/') a(ii).name];
                        WaitSecs(0.5);
        %                         a2=dir(filename);
                        %doesn't work with pl2
        %                         %if the file hasn't been updated in the last five
        %                         %second we assume we are not recording
        %                         %if etime(datevec(now),datevec(a(ii).datenum)) > 5 
        %                         if a(ii).bytes==a2.bytes
        %                             filename='NOTRECORDING';
        %                         end
        %                         
                        pnet(s.sock,'printf',['FILENAME' char(10)]);
                        pnet(s.sock,'printf',[filename char(10)]);
                        pnet(s.sock,'writepacket',s.clientip,double(s.clientport));
                end
                if s.continuous && s.clientisconnected
                    s= sentSpikes(s);
                end
        end

        function s=sentSpikes(s)
            ts=s.spikes(1:s.iSpikes,:);
            nspks = s.iSpikes;
            
            remove=all(ts'==0);
            ts(remove,:)=[];
            nspks=nspks-sum(remove);
            if s.eventsonly
                ts(ts(:,1) == 1,:)=[];
                nspks=size(ts,1);
            end

            if nspks > 0 %Received spikes
                fprintf('Sending %d spikes\n', nspks);

                %Send spikes in batches of 1000*96
                for ii = 1:ceil(size(ts,1)/s.maxpacketsize)
                    if ii >1 %DEBUGGING
                        disp('packet splicing ... if message is constant decrease port_pause and/or splice_pause in spikeserver.m')
                        WaitSecs(s.splice_pause)
                    end
                    %Write the spikes to the port
                    rg = (ii-1)*s.maxpacketsize+1:min(size(ts,1),ii*s.maxpacketsize);
                    pnet(s.sock,'printf',['SPIKES' char(10)]);
                    pnet(s.sock,'write', s.packetnum);
                    s.packetnum=s.packetnum+1;
                    %fprintf('Packet num %d\n', packetnum);
                    pnet(s.sock,'write',ts(rg,:));
                    pnet(s.sock,'writepacket',s.clientip,s.clientport);
                end
            else
                fprintf('No Spikes to send\n')
            end
            
            s.iSpikes=0;
        end
	end
end
    