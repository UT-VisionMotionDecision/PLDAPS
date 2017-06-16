classdef nansocket < pnetsocket
	properties
        baseDir='C:\nan\dce\toolswin\winkmi\';
%         continuous = false
    end
   
    methods 
%         function s = nansocket(port) 
%            s.port=port;
%         end

        function s = open(s,port) 
           s = open@pnetsocket(s,port);
        end

        function s=readAndReply(s)
            s=readAndReply@pnetsocket(s);
            switch s.instruction
                case 'GETNANPOSITIONS'
                     s = sendPositions(s,false);
            end
%             if s.continuous && s.clientisconnected
%                     s= sentSpikes(s, true);
%             end
        end
        function s = sendPositions(s, onlyChanges)
            a=dir([s.baseDir '*.txt']);
            %N=datenum({a.date});
            [~,ii]=max([a.datenum]);
            %a(ii).name

            filename=[strrep(s.baseDir,'\','/') a(ii).name];
    %                         filename='C:\nan\dce\toolswin\winkmi\03_November_2009_3.txt';
            [dat, pos]= nanread(filename);

            nantime=datenum([dat.day '-' dat.month '-' dat.year ' ' dat.hour ':' dat.minute ':' dat.second]);


            drives={pos.driveNr};
            drives=strrep(drives,'R_','1');
            drives=strrep(drives,'S_','2');
            drives=strrep(drives,'T_','3');
            drives=strrep(drives,'Z_','4');
            drives=str2double(drives);

            pnet(s.sock,'printf',['NANPOSITIONS' char(10)]);
            pnet(s.sock,'write',nantime);
            %pnet(s.sock,'printf',char(10));
            pnet(s.sock,'write',[drives'  str2double({pos.drivePos})']);
            %pnet(s.sock,'printf',char(10));
            pnet(s.sock,'writepacket',s.clientip,double(s.clientport));
         end
    end
end