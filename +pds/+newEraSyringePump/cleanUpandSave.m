function p = cleanUpandSave(p)

    if p.trial.newEraSyringePump.use
        [volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(p);
        p.trial.newEraSyringePump.volumeGiven = volumeGiven;
        p.trial.newEraSyringePump.volumeWithdrawn = volumeWithdrawn;
    end