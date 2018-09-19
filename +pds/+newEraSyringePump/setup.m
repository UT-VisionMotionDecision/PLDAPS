function p = setup(p)
% p = pds.newEraSyringePump.setup(p)
%
% sets up the connection to a New Era syringe pump (syringepump.com) via
% USB. Currently only modes that run a by defined volume per reward are implemented
%
% jk wrote it 2015
% 2018-04-26  TBC  Tuned up. Use blocking for more reliable initialization

if p.trial.newEraSyringePump.use
    
    % NO!! ...damn IOPort crashes & closes Screen if try to close a port thats not open! So damn hostile!!
    % %     % Prevent crash (...but effectively hardcodes pump handle, and will crash if grbl disabled)
    % %     IOPort('Close',1);
    % %     pause(.01)

    config='BaudRate=19200 DTR=1 RTS=1 ReceiveTimeout=1'; % orig
    %config= [config, ' Terminator=13 ProcessingMode=Cooked']; % nope...not compatible with pump comm
    
    %% Open port
    [h, errmsg]=IOPort('OpenSerialPort', p.trial.newEraSyringePump.port, config);   % Mac:'/dev/cu.usbserial' Linux:'/dev/ttyUSB0'

    WaitSecs(0.1);
    if ~isempty(errmsg)
        error('pds:newEraSyringePump:setup', 'Failed to open serial Port with message:\n\t%s\n', errmsg);
    end
    p.trial.newEraSyringePump.h = h;
    
    %% Configure pump
    blocking = 1; % these writes are not time sensitive, so use blocking
    % serial com line terminator  (..why in the world must this be set for twenty char(10)s??)
    p.trial.newEraSyringePump.commandSeparator = [char(13) repmat(char(10),1,20)];
    cmdTerminator = p.trial.newEraSyringePump.commandSeparator; % make code readable
    
    % Ensure pump is in "Rate Function" mode
    IOPort('Write', h, 'RAT FUN', blocking);
    % flush serial command pipeline (no command)
    IOPort('Write', h, cmdTerminator, blocking);
    % Pumping direction to INFuse   (INF==infuse, WDR==withdraw, REV==reverse current dir)
    IOPort('Write', h, ['DIR INF'  cmdTerminator], blocking);
    % "Low-noise" mode (0==off, 1==on; attempts to reduce high-freq noise from slow pump rates...unk. effect/utility in typical ephys enviro. --TBC)
    IOPort('Write', h, ['LN ' num2str(p.trial.newEraSyringePump.lowNoiseMode) cmdTerminator], blocking); %low noise mode, try
    % audible alarm state (0==off, 1==on/use)
    IOPort('Write', h, ['AL ' num2str(p.trial.newEraSyringePump.alarmMode) cmdTerminator], blocking); %low noise mode, try
    % set TTL trigger mode (see NE-500 user manual for other options & descriptions)
    %   'ST'==dispense on button/pedal press, repeats while held
    %   'T2'==dispense on button/pedal release, no repeats 
    IOPort('Write', h, ['TRG ' p.trial.newEraSyringePump.triggerMode  cmdTerminator], blocking);
    
    %% Special care with syringe diameter settings
    % Read out current syringe diameter before applying any changes
    %       why?...dia. changes will zero out pump's "volume dispensed", preventing tracking across Pldaps files in a session
    currentDiameter = getPumpDiameter(p);   % subfunction
    
    % Warn if different
    while currentDiameter~=p.trial.newEraSyringePump.diameter
        if p.trial.newEraSyringePump.allowNewDiameter
            IOPort('Write', h, ['DIA ' num2str(p.trial.newEraSyringePump.diameter) cmdTerminator], blocking);
        else
            fprintf(2, ['!!!\t Change in Diametersize requested.\n!!!\tDoing so would zero out the current volume '...
                        'settings & information [for this session]\n\nTo confirm that you want to do this, set \n'...
                        '\tp.trial.newEraSyringePump.allowNewDiameter = true;\n\n']);
            keyboard
        end
        % Refresh currentDiameter reported by pump
        currentDiameter = getPumpDiameter(p);   % subfunction
        fprintf('\n\tNew diameter %3.1f\n', currentDiameter);
    end
    
    %% Finish remaining setup
    % Pumping rate & units (def: 2900, 'MH')        ['MH'==mL/hour]
    IOPort('Write', h, ['RAT ' num2str(p.trial.newEraSyringePump.rate) ' MH ' cmdTerminator], blocking);%2900
    % Reward volume & units (def: 0.05, 'ML')
    IOPort('Write', h, ['VOL ' num2str(p.trial.behavior.reward.defaultAmount) ' ' p.trial.newEraSyringePump.volumeUnits cmdTerminator], blocking);%0.05
    
    
    IOPort('Read',h); %clear buffer
    %now read and store the current Volumes at the beginning of the
    %experiment. Don't reset to allow a volume that caputre the volume
    %dispensed over a whole session
    [volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(p);
    p.trial.newEraSyringePump.initialVolumeGiven = volumeGiven;
    p.trial.newEraSyringePump.initialVolumeWithdrawn = volumeWithdrawn;
end



end % end pds.newEraSyringePump.setup


% % % % % % % % % %
%% Sub-Functions
% % % % % % % % % %

%% getPumpDiameter
function currentDiameter = getPumpDiameter(p)

    % Request current diameter
    IOPort('Write', p.trial.newEraSyringePump.h, ['DIA' p.trial.newEraSyringePump.commandSeparator], 1);%0.05
    WaitSecs(0.1);
    % Read out current syringe diameter before applying any changes
    %       why?...dia. changes will zero out pump's "volume dispensed", preventing tracking across Pldaps files in a session
    thismany = IOPort('BytesAvailable', p.trial.newEraSyringePump.h);
    a = char(IOPort('Read', p.trial.newEraSyringePump.h, 1, thismany));
    % parse return string for S####, where #### is syringe diameter setting
    currentDiameter = str2double(a(find(a=='S',1,'last')+1:end-1));
    
end
