function [volumeGiven,volumeWithdrawn] = getVolume(p)
%pds.newEraSyringePump.getVolume   retrieves the current volume dispensed by the pump
%
% p = pds.newEraSyringePump.getVolume(p)
%
% jk wrote it 2015

if p.trial.newEraSyringePump.use
    %get current given volume and store
    h = p.trial.newEraSyringePump.h;
    IOPort('Read',h); %clear buffer
    IOPort('Write', h, ['DIS' p.trial.newEraSyringePump.commandSeparator],0);
    IOPort('Flush',h);
    a=[];
    timeout=0.1;
    starttime=GetSecs;
    while isempty(strfind(a,'ML'))&&isempty(strfind(a,'UL'))
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
    
    res=regexp(a,'00[SI][I](?<given>\d+.\d+)W(?<withdrawn>\d+.\d+)', 'names');
    if isempty(res)
        res=regexp(a,'00[SI][I](?<given>\d+.)W(?<withdrawn>\d+.\d+)', 'names');
    end
    
    volumeGiven = str2num(res.given);
    volumeWithdrawn = str2num(res.withdrawn);
    
else
    volumeGiven = NaN;
    volumeWithdrawn = NaN;
end

end %main function