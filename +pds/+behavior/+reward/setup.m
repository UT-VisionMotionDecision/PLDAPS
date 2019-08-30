function p = setup(p)
%pds.behavior.reward.setup(p)    setup reward systems before the experiment
% This is mostly a wrapper to the other reward modules.
    pds.newEraSyringePump.setup(p);

    %allocate memory in case reward is given during pause
    p.trial.behavior.reward.iReward     = 1; % counter for reward times
    p.trial.behavior.reward.timeReward  = nan(2,0); 
    
%     % match functionality of standard trial setup & cleanup to prevent extraneous empty fields in saved data struct (see reward.cleanupandsave )
%     p.trial.behavior.reward.timeReward(isnan(p.trial.behavior.reward.timeReward))=[];