function p = defaultBitNames(p)
% dv = defaultBitNames(dv)
% defaultBitNames adds .events.NAME to p.trial
% The MAP server can only take 7 unique bits. BIT names are:
%   1. FIXATION
%   2. STIMULUS
%   3. TARGS
%   4. REWARD
%   5. BREAKFIX
%   6. TRIALEND
%   7. TRIALSTART

% 12/12/2013 jly    Wrote it

p.trial.event.FIXATION  = 1;
p.trial.event.STIMULUS  = 2;
p.trial.event.TARGS     = 3;
p.trial.event.REWARD    = 4;
p.trial.event.BREAKFIX  = 5;
p.trial.event.TRIALEND  = 6;
p.trial.event.CHOICE    = 8;
p.trial.event.TRIALSTART = 7;