function p = cleanUpandSave(p)
%pds.newEraSyringePump.cleanUpandSave   save reward info after the trial
%
% stores the current volume dispensed by the pump
%
% p = pds.newEraSyringePump.cleanUpandSave(p)
%
% jk wrote it 2015

    if p.trial.newEraSyringePump.use
        [volumeGiven,volumeWithdrawn] = pds.newEraSyringePump.getVolume(p);
        p.trial.newEraSyringePump.volumeGiven = volumeGiven;
        p.trial.newEraSyringePump.volumeWithdrawn = volumeWithdrawn;
    end