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

dv.event.FIXATION  = 1;
dv.event.STIMULUS  = 2;
dv.event.TARGS     = 3;
dv.event.REWARD    = 4;
dv.event.BREAKFIX  = 5;
dv.event.TRIALEND  = 6;
dv.event.CHOICE    = 8;
dv.event.TRIALSTART = 7;