function p = defaultBitNames(p)
% p = defaultBitNames(p)
% defaultBitNames adds .events.NAME to dv
% The MAP server can only take 7 unique bits. BIT names are:
%   1. FIXATION
%   2. STIMULUS
%   3. TARGS
%   4. REWARD
%   5. BREAKFIX
%   6. TRIALEND
%   7. TRIALSTART

% 12/12/2013 jly    Wrote it

p.defaultParameters.event.FIXATION  = 1;
p.defaultParameters.event.STIMULUS  = 2;
p.defaultParameters.event.TARGS     = 3;
p.defaultParameters.event.REWARD    = 4;
p.defaultParameters.event.BREAKFIX  = 5;
p.defaultParameters.event.TRIALEND  = 6;
p.defaultParameters.event.CHOICE    = 8;
p.defaultParameters.event.TRIALSTART = 7;