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
%     end
    
%     if p.trial.newEraSyringePump.allowNewDiameter
%         % allow new diameter clears the starting volume dispensed record, and must be enabled for any safe assumption that
%         % the volumes reported are [reasonably] correct
        if isfield(p.trial.newEraSyringePump,'refillVol') && ~isempty(p.trial.newEraSyringePump.refillVol)
            if (p.trial.newEraSyringePump.volumeGiven-p.trial.newEraSyringePump.volumeWithdrawn) > p.trial.newEraSyringePump.refillVol
                p = pds.newEraSyringePump.refill(p, p.trial.newEraSyringePump.refillVol);
            end
        end
    end