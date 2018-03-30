function p = setup(p)
%pds.newEraSyringePump.getVolume   sets up connection to a New Era syringe pump
%
% p = pds.newEraSyringePump.setup(p)
% sets up the connection to a New Era syringe pump (syringepump.com) via
% USB. Currently only modes that run a by defined volume per reward are implemented
%
% jk wrote it 2015

if p.trial.newEraSyringePump.use
    config='BaudRate=19200 DTR=1 RTS=1 ReceiveTimeout=1'; % orig
    %config= [config, ' Terminator=13 ProcessingMode=Cooked'];
    % Nooo. All IOPort connections now closed at start of p.run
    %     IOPort('closeAll'); %risky. for now....
    %     WaitSecs(0.1);
    
    %% Open port
    [h, errmsg]=IOPort('OpenSerialPort', p.trial.newEraSyringePump.port, config);% Mac:'/dev/cu.usbserial' Linux:'/dev/ttyUSB0'
    WaitSecs(0.1);
    if ~isempty(errmsg)
        error('pds:newEraSyringePump:setup',['Failed to open serial Port with message ' char(10) errmsg]);
    end
    p.trial.newEraSyringePump.h = h;
    
    %% Configure pump
    % serial com line terminator
    p.trial.newEraSyringePump.commandSeparator = [char(13) repmat(char(10),1,20)];
    
    % flush serial command pipeline (no command)
    IOPort('Write', h, [p.trial.newEraSyringePump.commandSeparator],0);
    % set syringe diameter (...but don't yet, because value is empty here. Why??? --TBC)
    IOPort('Write', h, ['DIA' p.trial.newEraSyringePump.commandSeparator],0);%0.05
    % set pumping direction to INFuse   (INF==infuse, WDR==withdraw, REV==reverse current dir)
    IOPort('Write', h, ['DIR INF'  p.trial.newEraSyringePump.commandSeparator],0);
    % enable/disable low-noise mode (logical, attempts to reduce high-freq noise from slow pump rates...unk. effect/utility in typical ephys enviro. --TBC)
    IOPort('Write', h, ['LN ' num2str(p.trial.newEraSyringePump.lowNoiseMode) p.trial.newEraSyringePump.commandSeparator],0); %low noise mode, try
    % enable/disable audible alarm state (0==off, 1==on/use)
    IOPort('Write', h, ['AL ' num2str(p.trial.newEraSyringePump.alarmMode) p.trial.newEraSyringePump.commandSeparator],0); %low noise mode, try
    % set TTL trigger mode ('T2'=="Rising edge starts pumping program";  see NE-500 user manual for other options & descriptions)
    IOPort('Write', h, ['TRG ' p.trial.newEraSyringePump.triggerMode  p.trial.newEraSyringePump.commandSeparator],0);
    
    %%
    WaitSecs(0.1);
    % Read out current syringe diameter before applying any changes
    %       why?...dia. changes will zero out machine 'volume dispensed' & would erase record between Pldaps files in a session
    a=char(IOPort('Read',h,1,14));
    currentDiameter=str2double(a(10:end));
    % Warn if different
    while currentDiameter~=p.trial.newEraSyringePump.diameter
        if p.trial.newEraSyringePump.allowNewDiameter
            IOPort('Write', h, ['DIA ' num2str(p.trial.newEraSyringePump.diameter) p.trial.newEraSyringePump.commandSeparator],0);
            % Refresh currentDiameter reported by pump
            WaitSecs(0.1);
            IOPort('Write', h, ['DIA' p.trial.newEraSyringePump.commandSeparator],0);
            WaitSecs(0.1);
            a=char(IOPort('Read',h,1,14));
            currentDiameter=str2double(a(10:end));
        else
            %error('pds:newEraSyringePump:setup','Change in Diametersize requested. Please confirm that you want to do this, as it would zero the current volume settings')
            fprintf(2, '!!!\t Change in Diametersize requested.\n!!!\tDoing so would zero out the current volume settings & information [for this session]\n\nTo confirm that you want to do this, set \n\tp.trial.newEraSyringePump.allowNewDiameter = true;\n\n');
            keyboard
        end
    end
    %%
    % set pumping rate & units (def: 2900, 'MH')        ['MH'==mL/hour]
    IOPort('Write', h, ['RAT ' num2str(p.trial.newEraSyringePump.rate) ' MH ' p.trial.newEraSyringePump.commandSeparator],0);%2900
    % set reward volume & units (def: 0.05, 'ML')
    IOPort('Write', h, ['VOL ' num2str(p.trial.behavior.reward.defaultAmount) ' ' p.trial.newEraSyringePump.volumeUnits p.trial.newEraSyringePump.commandSeparator],0);%0.05
    
    
%     a=char(IOPort('Read',h)); %clear buffer

    %now read and store the current Volumes at the beginning of the
    %experiment. Don't reset to allow a volume that caputre the volume
    %dispensed over a whole session
    [volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(p);
    p.trial.newEraSyringePump.initialVolumeGiven = volumeGiven;
    p.trial.newEraSyringePump.initialVolumeWithdrawn = volumeWithdrawn;
end