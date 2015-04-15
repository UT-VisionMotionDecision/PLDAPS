function p = stop(p)

    if p.trial.newEraSyringePump.use
        %get current given volume and store
        h = p.trial.newEraSyringePump.h;
        IOPort('Write', h, ['STP' p.trial.newEraSyringePump.commandSeparator],0);
    end