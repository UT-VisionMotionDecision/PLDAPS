function p = give(p, amount)

    if nargin < 2
        amount = p.trial.behavior.reward.defaultAmount;
    end

    pds.newEraSyringePump.give(p,amount);
      
	if p.trial.datapixx.use
        if  p.trial.datapixx.useForReward
            pds.datapixx.analogOut(amount);
        end
        %%flag
        pds.datapixx.flipBit(p.trial.event.REWARD,p.trial.pldaps.iTrial);
	end
    
    %%sound
    if p.trial.sound.use
        PsychPortAudio('Start', p.trial.sound.reward);
    end
    
    %% store data
    p.trial.behavior.reward.timeReward(:,p.trial.behavior.reward.iReward) = [p.trial.ttime amount];
	p.trial.behavior.reward.iReward = p.trial.behavior.reward.iReward + 1;
   	