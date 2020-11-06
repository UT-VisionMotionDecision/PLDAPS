function p = getQueue(p)
% function p = pds.keyboard.getQueue(p)
% 
% Retrieve any key presses/releases recorded by KbQueue, and store rolling account of keyboard activity
% in pldaps structure
% 
% TBC:  Consider reducing inputs/outputs the .keyboard substruct, to improve speed if less bloat
%       from pldaps structure is passed back & forth
%   e.g.)   p.trial.keyboard = pds.keyboard.getQueue( p.trial.keyboard, p.trial.iFrame);
% 
%
% 2020-01-07  TBC  Extracted code block from pldapsDefaultTrialFunction.m ...long overdue, but still in need of real refinement

% Check keyboard
[p.trial.keyboard.pressedQ, p.trial.keyboard.firstPressQ, firstRelease, lastPress, lastRelease] = KbQueueCheck(p.trial.keyboard.devIdx); % fast

if p.trial.keyboard.pressedQ || any(firstRelease)
    n = p.trial.keyboard.samples+1;
    p.trial.keyboard.samplesTimes(n) = GetSecs;
    p.trial.keyboard.samplesFrames(n) = p.trial.iFrame;
    p.trial.keyboard.pressedSamples(:,n) = p.trial.keyboard.pressedQ;
    p.trial.keyboard.firstPressSamples(:,n) = p.trial.keyboard.firstPressQ;
    p.trial.keyboard.firstReleaseSamples(:,n) = firstRelease;
    p.trial.keyboard.lastPressSamples(:,n) = lastPress;
    p.trial.keyboard.lastReleaseSamples(:,n) = lastRelease;
    
    p.trial.keyboard.samples = n;
    p = pds.keyboard.checkModKeys(p);
end

% Update this regardless of press/release event so that acts as momentary detector
p = pds.keyboard.checkNumKeys(p);
