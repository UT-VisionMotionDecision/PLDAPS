function dv = defaultBitNames(dv)
% dv = defaultBitNames(dv)
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

dv.events.FIXATION  = 1;
dv.events.STIMULUS  = 2;
dv.events.TARGS     = 3;
dv.events.REWARD    = 4;
dv.events.BREAKFIX  = 5;
dv.events.TRIALEND  = 6;
dv.events.CHOICE    = 8;
dv.events.TRIALSTART = 7;