function p = give(p, amount)
%pds.newEraSyringePump.five   dispense a specified amount of volume
%
% p = pds.newEraSyringePump.getVolume(p)
%
% jk wrote it 2015

    if p.trial.newEraSyringePump.use
        if nargin <2 %repeat last given Volume
            IOPort('Write', p.trial.newEraSyringePump.h, ['RUN' p.trial.newEraSyringePump.commandSeparator],0);
        elseif amount>=0.001
%             IOPort('Write', p.trial.newEraSyringePump.h, ['VOL ' num2str(amount) p.trial.newEraSyringePump.commandSeparator],0);
%             IOPort('Write', p.trial.newEraSyringePump.h, ['RUN' p.trial.newEraSyringePump.commandSeparator],0);
            IOPort('Write', p.trial.newEraSyringePump.h, ['VOL ' sprintf('%3.3f',amount) p.trial.newEraSyringePump.commandSeparator 'RUN' p.trial.newEraSyringePump.commandSeparator],0);
        end
    end