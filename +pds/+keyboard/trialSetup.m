function trialSetup(p)
% function pds.keyboard.trialSetup(p)
% 
% Standard keyboard struct initialization for each trial
% 
% 2020-10-12 TBC  Functionified
% 

% Initialize this many values for each trial
%   TBC:  unk. why "*1.1"
n   = round(p.trial.pldaps.maxFrames*1.1);
k   = p.trial.keyboard.nCodes;

p.trial.keyboard.samples                = 0;
p.trial.keyboard.samplesTimes           = zeros(1, n);
p.trial.keyboard.samplesFrames          = zeros(1, n);
p.trial.keyboard.pressedSamples         = false(1, n);
p.trial.keyboard.firstPressSamples      = zeros(k, n);
p.trial.keyboard.firstReleaseSamples    = zeros(k, n);
p.trial.keyboard.lastPressSamples       = zeros(k, n);
p.trial.keyboard.lastReleaseSamples     = zeros(k, n);

end %main function