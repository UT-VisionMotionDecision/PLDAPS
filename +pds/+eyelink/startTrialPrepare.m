function p = startTrialPrepare(p)
%pds.eyelink.startTrialPrepare   prepare the next trial
%
% gets and eylink time estimate and send a TRIALSTART message to eyelink
%
% p = startTrialPrepare(p)

if p.trial.eyelink.use
    p.trial.timing.eyelinkStartTime = pds.eyelink.getPreciseTime(6.5e-5,0.1,2);
    Eyelink('message', 'TRIALSTART');
end
 