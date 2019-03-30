function outputState = isActive(p)

    % Request current state of pumping output ttl pin
    IOPort('Write', p.trial.newEraSyringePump.h, ['ROM' p.trial.newEraSyringePump.commandSeparator], 1); %0.05
    WaitSecs(0.03);
    % Read out response
    thismany = IOPort('BytesAvailable', p.trial.newEraSyringePump.h);
    resp = char(IOPort('Read', p.trial.newEraSyringePump.h, 1, thismany));
    outputState = resp(end-2)~='S';
%     % parse return string for S####, where #### is syringe diameter setting
%     outputState = str2double(a(find(a=='S',1,'last')+1:end-1));
    
end