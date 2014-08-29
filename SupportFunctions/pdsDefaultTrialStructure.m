function p = pdsDefaultTrialStructure(p)
% p = pdsDefaultTrialStructure(p)
% pdsDefaultTrialStructure sets up the dv struct for displaying all the
% standard task parameters we use in huk lab

% 12/2013 jly   Wrote it
p.defaultParameters.good = 1;

p.defaultParameters.stimulus.photodiode.use = 1;
p.defaultParameters.stimulus.photodiode.location = 2;
p.defaultParameters.stimulus.photodiode.frames = 10;


if ~isfield(p.defaultParameters,'pldaps.finish')
    p.defaultParameters.pldaps.finish = inf;
end

p.defaultParameters.stimulus.randomNumberGenerater = 'mt19937ar';


% Setup Timings
%-------------------------------------------------------------------------%
% Reward time: is time that solenoid is opened for. set to 100 miliseconds
% for mapping trials.
p.defaultParameters.stimulus.rewardTime = .1;
p.defaultParameters.stimulus.rewardWait = 0;
p.defaultParameters.stimulus.breakFixPenalty = 2;
p.defaultParameters.stimulus.jitterSize = .5;
% fixation
p.defaultParameters.stimulus.preTrial     = .5;
p.defaultParameters.stimulus.fixWait      = 4;
p.defaultParameters.stimulus.fixHold      = 1;

% targets
p.defaultParameters.stimulus.targWait   = 1.5;
p.defaultParameters.stimulus.targHold   = 0.5;
p.defaultParameters.stimulus.targOnset  = [0.1 0.1];
p.defaultParameters.stimulus.targDuration = [2 .2];

% Colors
%-------------------------------------------------------------------------%
p = defaultColors(p);

% Bits
%-------------------------------------------------------------------------%
p = defaultBitNames(p);

% dot sizes for drawing
p.defaultParameters.stimulus.eyeW      = 8;    % eye indicator width in pixels
p.defaultParameters.stimulus.fixdotW   = 8;    % width of the fixation dot
p.defaultParameters.stimulus.targdotW  = 8;    % width of the target dot
p.defaultParameters.stimulus.cursorW   = 8;   % cursor width in pixels

% States
%-------------------------------------------------------------------------%
p.defaultParameters.stimulus.states.START     = 1;
p.defaultParameters.stimulus.states.FPON      = 2;
p.defaultParameters.stimulus.states.FPHOLD    = 3;
p.defaultParameters.stimulus.states.CHOOSETARG = 4;
p.defaultParameters.stimulus.states.HOLDTARG     = 5;
p.defaultParameters.stimulus.states.BREAKFIX  = 7;
p.defaultParameters.stimulus.states.TRIALCOMPLETE = 6;



