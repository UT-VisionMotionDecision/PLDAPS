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

dv.defaultParameters.event.FIXATION  = 1;
dv.defaultParameters.event.STIMULUS  = 2;
dv.defaultParameters.event.TARGS     = 3;
dv.defaultParameters.event.REWARD    = 4;
dv.defaultParameters.event.BREAKFIX  = 5;
dv.defaultParameters.event.TRIALEND  = 6;
dv.defaultParameters.event.CHOICE    = 8;
dv.defaultParameters.event.TRIALSTART = 7;