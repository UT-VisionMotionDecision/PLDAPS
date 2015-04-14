function [volumeGiven,volumeWithdrawn] = getVolume(p)

    if p.trial.newEraSyringePump.use
        %get current given volume and store
        h = p.trial.newEraSyringePump.h;
        IOPort('Read',h); %clear buffer
        IOPort('Write', h, ['DIS' p.trial.newEraSyringePump.commandSeparator],0);
        IOPort('Flush',h);
        a=[];
        timeout=0.1;
        starttime=GetSecs;
%         tic;
        while isempty(strfind(a,'ML'))
            if GetSecs > starttime+timeout
                warning('pds:newEraSyringePump:getVolume','Timed out getting Volume');
                volumeGiven = NaN;
                volumeWithdrawn = NaN;
                return
            end
            WaitSecs(0.001);
            anew=char(IOPort('Read',h));
            if ~isempty(anew)
                a=[a anew]; %#ok<AGROW>
                starttime=GetSecs;
            end
        end
%         display('getVolume')
%         toc*1000
%         start=strfind(a,'00SI');
%         start2=strfind(a,'W');
%         end2=strfind(a,'ML');
% 
%         start=start(end)+4;       
%         start2=start2(end);
%         end2=end2(end);
%         volumeGiven = str2double(a(start:start2-1));
%         volumeWithdrawn = str2double(a(start2+1:end2-1));
        res=regexp(a,'00[SI]I(?<given>\d+.\d+)W(?<withdrawn>\d+.\d+)', 'names');
        volumeGiven = res.given;
        volumeWithdrawn = res.withdrawn;
    else
        volumeGiven = NaN;
        volumeWithdrawn = NaN;
    end