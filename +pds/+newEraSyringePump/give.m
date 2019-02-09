function p = give(p, amount)
% p = pds.newEraSyringePump.give(p, amount)
% 
% Dispense a specified amount of volume
%   (default = same as last volume given)
% 
%   ** Avoids reward volume = 0, which pump interprets as continuous pumping(!)
% 
% jk wrote it 2015
% 2019-02-08  TBC  cleaned

    if p.trial.newEraSyringePump.use
        if nargin <2
            % repeat last given Volume
            IOPort('Write', p.trial.newEraSyringePump.h, ['RUN' p.trial.newEraSyringePump.commandSeparator],0);
            
        elseif amount>=0.001 && amount<=9999
            % wtf!??      IOPort('Write', p.trial.newEraSyringePump.h, ['VOL ' sprintf('%*.*f', ceil(log10(amount)), min(3-ceil(log10(amount)),3),amount) p.trial.newEraSyringePump.commandSeparator 'RUN' p.trial.newEraSyringePump.commandSeparator],0);
            IOPort('Write', p.trial.newEraSyringePump.h, ['VOL ' sprintf('%3.3f', amount) p.trial.newEraSyringePump.commandSeparator...
                                                          'RUN' p.trial.newEraSyringePump.commandSeparator], 0);
        end
    end
    
    
   