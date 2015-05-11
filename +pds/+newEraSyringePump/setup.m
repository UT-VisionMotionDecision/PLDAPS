function p = setup(p)
%pds.newEraSyringePump.getVolume   sets up connection to a New Era syringe pump
%
% p = pds.newEraSyringePump.setup(p)
% sets up the connection to a New Era syringe pump (syringepump.com) via
% USB. Currently only modes that run a by defined volume per reward are implemented
%
% jk wrote it 2015

if p.trial.newEraSyringePump.use
    cs='BaudRate=19200 DTR=1 RTS=1 ReceiveTimeout=1';
    IOPort('closeAll'); %risky. for now....
    WaitSecs(0.1);
    [h,errmsg]=IOPort('OpenSerialPort',p.trial.newEraSyringePump.port,cs);%'/dev/cu.usbserial'
    WaitSecs(0.1);
    if ~isempty(errmsg)
        error('pds:newEraSyringePump:setup',['Failed to open serial Port with message ' char(10) errmsg]);
    end
    p.trial.newEraSyringePump.h = h;
    
    p.trial.newEraSyringePump.commandSeparator = [char(13) repmat(char(10),1,20)];

    IOPort('Write', h, [p.trial.newEraSyringePump.commandSeparator],0);
    IOPort('Write', h, ['DIA' p.trial.newEraSyringePump.commandSeparator],0);%0.05
    
    IOPort('Write', h, ['DIR INF'  p.trial.newEraSyringePump.commandSeparator],0);

    IOPort('Write', h, ['LN ' num2str(p.trial.newEraSyringePump.lowNoiseMode) p.trial.newEraSyringePump.commandSeparator],0); %low noise mode, try
    
    IOPort('Write', h, ['AL ' num2str(p.trial.newEraSyringePump.alarmMode) p.trial.newEraSyringePump.commandSeparator],0); %low noise mode, try

    IOPort('Write', h, ['TRG T2'  p.trial.newEraSyringePump.commandSeparator],0);
    
    WaitSecs(0.1);
    a=char(IOPort('Read',h,1,14));
    currentDiameter=str2double(a(10:end));
    
    if currentDiameter~=p.trial.newEraSyringePump.diameter
        if p.trial.newEraSyringePump.allowNewDiameter
            IOPort('Write', h, ['DIA ' num2str(p.trial.newEraSyringePump.diameter) p.trial.newEraSyringePump.commandSeparator],0); 
        else
            error('pds:newEraSyringePump:setup','Change in Diametersize requested. Please confirm that you want to do this, as it would zero the current volume settings')
        end
    end
    
    IOPort('Write', h, ['RAT ' num2str(p.trial.newEraSyringePump.rate) ' MH ' p.trial.newEraSyringePump.commandSeparator],0);%2900

    IOPort('Write', h, ['VOL ' num2str(p.trial.behavior.reward.defaultAmount) p.trial.newEraSyringePump.commandSeparator],0);%0.05
    
    
%     a=char(IOPort('Read',h)); %clear buffer
    %now read and store the current Volumes at the beginning of the
    %experiment. Don't reset to allow a volume that caputre the volume
    %dispensed over a whole session
    [volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(p);
    p.trial.newEraSyringePump.initialVolumeGiven = volumeGiven;
    p.trial.newEraSyringePump.initialVolumeWithdrawn = volumeWithdrawn;
end