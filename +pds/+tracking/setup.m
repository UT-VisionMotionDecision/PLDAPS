function p = setup(p, sn)
% function p = pds.tracking.setup(p)
% 
% Setup & initialization of tracking module for tracking binocular or monocular eye position,
% or [potentially] other devices/things.
% -- This function gets called by pldapsDefaultTrial.m, prior to opening the PTB screen
% -- It sets up the tracking module to be executed immediately after the default trial function
% -- Additional setup (incl. determining tracking source) occurs in pds.tracking.postOpenScreen
% 
% =======
% Activate calibration trial from pause state by calling:
%       pds.tracking.runCalibrationTrial(p)  % i.e. nargin==1
% 
% How is the .tracking module different from direct usage (e.g. p.trial.eyelink)?
%   (1) it takes care of device calibration, allowing for monocular or [truly] binocular eyetracking,
%       and gives user more active control to save/recall/manipulate the mapping of tracker-to-world
%   (2) allows experiment code to be more ambiguous to what is being tracked (e.g. eye, hand, mouse)
%       and ambiguous to the particular device is being used (e.g. eyelink, LeapMotion, Vpixx, etc)
% 
% See also:  pds.tracking.runCalibrationTrial, pds.tracking.postOpenScreen
% 
% 2020-01-xx  TBC  Wrote it.
% 2020-03-03  TBC  Cleaning.
% 

% NOTE: presumably setting up module(s) inside pldapsDefaultTrial's 'experimentPreOpenScreen' state
% would preclude them from running in that state

% Set module order to run immediately after calling module (pldapsDefaultTrial.m)
snMod = 'tracking';
tmp =  pldapsModule('modName',snMod, 'name','pds.tracking.runCalibrationTrial', 'order', p.trial.(sn).stateFunction.order+1);%,...
    % 'requestedStates', {'frameUpdate','framePrepareDrawing','frameDraw','frameGLDrawLeft','frameGLDrawRight','trialItiDraw','trialSetup','trialPrepare','trialCleanUpandSave','experimentPreOpenScreen','experimentPostOpenScreen','experimentCleanUp'});

% .on should not be manually activated
% - execution of pds.tracking.runCalibrationTrial(p) carries out important toggling of other modules in the process
tmp.on = false;

fn = fieldnames(tmp);
for i = 1:length(fn)
    p.trial.(snMod).(fn{i}) = tmp.(fn{i});
end

