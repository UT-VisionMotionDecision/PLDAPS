function dv = pdsDefaultTrialStructure(dv)
% dv = pdsDefaultTrialStructure(dv)
% pdsDefaultTrialStructure sets up the dv struct for displaying all the
% standard task parameters we use in huk lab

% 12/2013 jly   Wrote it
dv.goodtrial = 0; 
dv.disp.photodiode = 1; 
dv.disp.photodiodeRect = makePhotodiodeRect(dv, 2); 
dv.disp.photodiodeFrames = 10;

dv.pa.randomNumberGenerater = 'mt19937ar';
% log timestamps
PsychDataPixx('LogOnsetTimestamps', 0);
PsychDataPixx('LogOnsetTimestamps', 2);

% Setup Timings
%-------------------------------------------------------------------------%
% Reward time: is time that solenoid is opened for. set to 100 miliseconds 
% for mapping trials. 
dv.pa.rewardTime = .1;
dv.pa.rewardWait = 0; 
dv.pa.breakFixPenalty = 2;
dv.pa.jitterSize = .5;
% fixation
dv.pa.preTrial     = .5;       
dv.pa.fixWait      = 4;        
dv.pa.fixHold      = 1;

% targets
dv.pa.targWait   = 1.5;
dv.pa.targHold   = 0.5;
dv.pa.targOnset  = [0.1 0.1];
dv.pa.targDuration = [2 .2];

% Colors
%-------------------------------------------------------------------------%
dv = defaultColors(dv);

% Tick Marks
%-------------------------------------------------------------------------%
dv = initTicks(dv); 

% Bits
%-------------------------------------------------------------------------%
dv = defaultBitNames(dv); 

% dot sizes for drawing
dv.pa.eyeW      = 8;    % eye indicator width in pixels
dv.pa.fixdotW   = 8;    % width of the fixation dot
dv.pa.targdotW  = 8;    % width of the target dot
dv.pa.cursorW   = 8;   % cursor width in pixels

% States
%-------------------------------------------------------------------------%
dv.states.START     = 1;
dv.states.FPON      = 2;
dv.states.FPHOLD    = 3;
dv.states.CHOOSETARG = 4;
dv.states.HOLDTARG     = 5;
dv.states.BREAKFIX  = 7;
dv.states.TRIALCOMPLETE = 6;

% Audio
%-------------------------------------------------------------------------%
dv = pdsAudioSetup(dv); 

