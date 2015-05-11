function p = stop(p)
%pds.newEraSyringePump.stop   stop dispensing
%
% p = pds.newEraSyringePump.stop(p)
%
% jk wrote it 2015

    if p.trial.newEraSyringePump.use
        %get current given volume and store
        h = p.trial.newEraSyringePump.h;
        IOPort('Write', h, ['STP' p.trial.newEraSyringePump.commandSeparator],0);
    end