function dv = pdsDefaultTrialStructure(dv)
% dv = pdsDefaultTrialStructure(dv)
% pdsDefaultTrialStructure sets up the dv struct for displaying all the
% standard task parameters we use in huk lab

% 12/2013 jly   Wrote it
dv.defaultParameters.good = 1;

dv.defaultParameters.stimulus.photodiode.use = 1;
dv.defaultParameters.stimulus.photodiode.location = 2;
dv.defaultParameters.stimulus.photodiode.frames = 10;


if ~isfield(dv.defaultParameters,'pldaps.finish')
    dv.defaultParameters.pldaps.finish = inf;
end

dv.defaultParameters.stimulus.randomNumberGenerater = 'mt19937ar';


% Setup Timings
%-------------------------------------------------------------------------%
% Reward time: is time that solenoid is opened for. set to 100 miliseconds
% for mapping trials.
dv.defaultParameters.stimulus.rewardTime = .1;
dv.defaultParameters.stimulus.rewardWait = 0;
dv.defaultParameters.stimulus.breakFixPenalty = 2;
dv.defaultParameters.stimulus.jitterSize = .5;
% fixation
dv.defaultParameters.stimulus.preTrial     = .5;
dv.defaultParameters.stimulus.fixWait      = 4;
dv.defaultParameters.stimulus.fixHold      = 1;

% targets
dv.defaultParameters.stimulus.targWait   = 1.5;
dv.defaultParameters.stimulus.targHold   = 0.5;
dv.defaultParameters.stimulus.targOnset  = [0.1 0.1];
dv.defaultParameters.stimulus.targDuration = [2 .2];

% Colors
%-------------------------------------------------------------------------%
dv = defaultColors(dv);

% Bits
%-------------------------------------------------------------------------%
dv = defaultBitNames(dv);

% dot sizes for drawing
dv.defaultParameters.stimulus.eyeW      = 8;    % eye indicator width in pixels
dv.defaultParameters.stimulus.fixdotW   = 8;    % width of the fixation dot
dv.defaultParameters.stimulus.targdotW  = 8;    % width of the target dot
dv.defaultParameters.stimulus.cursorW   = 8;   % cursor width in pixels

% States
%-------------------------------------------------------------------------%
dv.defaultParameters.stimulus.states.START     = 1;
dv.defaultParameters.stimulus.states.FPON      = 2;
dv.defaultParameters.stimulus.states.FPHOLD    = 3;
dv.defaultParameters.stimulus.states.CHOOSETARG = 4;
dv.defaultParameters.stimulus.states.HOLDTARG     = 5;
dv.defaultParameters.stimulus.states.BREAKFIX  = 7;
dv.defaultParameters.stimulus.states.TRIALCOMPLETE = 6;



