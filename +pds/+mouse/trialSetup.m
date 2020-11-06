function trialSetup(p)
% function pds.mouse.trialSetup(p)
% 
% Standard mouse struct initialization for each trial
% 
% 2020-10-12 TBC  Functionified
% 

% Initialize this many values for each trial
%   TBC:  unk. why "*1.1"
n   = round(p.trial.pldaps.maxFrames*1.1);
[~,~,buttonState] = GetMouse();

p.trial.mouse.samples               = 0;
p.trial.mouse.samplesTimes          = zeros(1, n);
p.trial.mouse.cursorSamples         = zeros(2, n);
p.trial.mouse.buttonPressSamples    = zeros(length(buttonState), n);

end %main function