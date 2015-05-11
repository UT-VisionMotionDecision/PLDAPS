function p = cleanUpandSave(p)
%pds.behavior.reward.cleanUpandSave(p)    clean up after a trial
% Store any necessary data from the different reward modules. This is 
% mostly a wrapper to the other modules. But also removes any unused fields
% of p.trial.behavior.reward.timeReward

    pds.newEraSyringePump.cleanUpandSave(p);
    
    %nothing to do for other reward modes
    p.trial.behavior.reward.timeReward(isnan(p.trial.behavior.reward.timeReward))=[];