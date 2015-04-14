% clean up after a trial. Store any necessary data from the different
% reward modules. This is mostly a wrapper to the other modules

function p = cleanUpandSave(p)

    pds.newEraSyringePump.cleanUpandSave(p);
    
    %nothing to do for other reward modes
    
    p.trial.behavior.reward.timeReward(isnan(p.trial.behavior.reward.timeReward))=[];