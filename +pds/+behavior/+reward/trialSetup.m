function p = trialSetup(p)

    p.trial.behavior.reward.iReward     = 1; % counter for reward times
    p.trial.behavior.reward.timeReward  = nan(2,p.trial.pldaps.maxTrialLength*2); %preallocate for a reward up to every 0.5 s