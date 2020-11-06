function [p] = doRfPos_gabGrid(subj, stimMode, viewdist)
% function [p] = modularDemo.doRfPos_gabGrid(subj, stimMode, viewdist)
% 
% Tutorial code for modular PLDAPS experimental design
% 
% INPUTS:
%   [subj]      Subject/session identifier  ("string", default: "test")
%   [stimMode]  Stimulus type               ("string", default: "gabors")   (...no other modes currently defined)
%   [viewdist]  
% 
% 
%   [pss] is the PLDAPS settings struct that is used to initialize modules
%   & parameters for this experimental session, and makeup the standard [p.trial]
%   structure that is integral to PLDAPS.
% 
% ----------------
% USAGE:
%   No inputs necessary to run demo from command window:
%   >> p = modularDemo.doRfPos_gabGrid
% 
% 
%   TRACKING CALIBRATION
%   To adjust eye/mouse tracking calibration:
%   - pause the experiment by pressing [p] key during a trial
%   - From the command window, start a tracking calibration trial:
%     >> pds.tracking.runCalibrationTrial(p)
%   - Follow directions printed in command window; briefly:
%     - [0] to reveal first fixation point
%     - [spacebar] to record fixation & advance to next point
%     - [u] to update calibration once sufficient points (>=10) have been recorded
%     - [p] to exit calibration, save to file, & return to pause state
%   
% 
% 2018-xx-xx TBC  Wrote it for RF mapping
% 2020-10-xx TBC  Updated to use consistent OpenGL rendering coordinates at screen center
% 2020-11-05 TBC  Cleaned & commented for modular tutorial
% 


KbName('UnifyKeyNames');

if nargin<1 || isempty(subj)
    subj = "test"; % "string" input preferred over 'char'
end
% stimMode == statename of stimulus module of interest
if nargin<2 || isempty(stimMode)
    stimMode = 'gabors';
end

% Set this module as the active stimulus module
%  (tells pmBase where to look for frame limits...incomplete implementation)
pss.pldaps.modNames.currentStim = {stimMode};

    
if nargin<3 || isempty(viewdist)
    viewdist = 57.29; % 57.29 == (1cm == 1deg)
end


pss.pldaps.pause.preExperiment = 0;

% 
% TUTORIAL TIP:
%   When learning/debugging PLDAPS, its helpful to set debug points inside your
%   modules so that you can examine how elements of your experiment operate/interact.
%   Overriding the default pldaps.trialMasterFunction ('runModularTrial') with the
%   following line:
pss.pldaps.trialMasterFunction = 'runModularTrial_frameLock';
%   will allow you to manually step through your code without trial time elapsing.
%   -!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-
%   -----DO NOT use the  _frameLock  variant in your normal experiments!--------------
%   Since this _frameLock version completely breaks PLDAPS time keeping accuracy, a prominent
%   warning will be displayed in the command window when this trial function is used.
%   When running an proper experiment, best practice is to let .trialMasterFunction
%   inherit the default value from pldapsClassDefault.m by not setting it at all.
%   -!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-
% 

pss.newEraSyringePump.use = false;
pss.newEraSyringePump.refillVol = 40;
pss.behavior.reward.defaultAmount = 0.16;

fixRadius = 3; %[deg], applied to fixation module below


%% Eyepos & Eyelink
pss.eyelink.use = false;

pss.eyelink.useAsEyepos = pss.eyelink.use;
% make .mouse param respect eyelink use state
pss.mouse.useAsEyepos = ~pss.eyelink.useAsEyepos;
pss.pldaps.draw.eyepos.use = true;


%% Module inventory:
% -100: pldaps default trial function
%  1:   fixation
%  2:    base timing module
%  10:   gabor stim drawing module


%% display settings
pss.display.viewdist = viewdist;  % 57.29 == (1cm == 1deg)
pss.display.ipd = 6.5;  % human == 6.5;  macaque == 3.25;
pss.display.useOverlay = 1;

% pss.display.screenSize = [];
% pss.display.scrnNum = 0;

pss.display.stereoMode = 4;

pss.display.useGL = 1;
pss.display.multisample = 2;


%% (-100) pldaps default trial function
sn = 'pdTrialFxn'; % modName
pss.(sn) = pldapsModule('modName',sn, 'name','pldapsDefaultTrial', 'order',-100);


%% (1) fixation module
% see help  modularDemo.pmFixDot
sn = 'fix';
pss.(sn) =  pldapsModule('modName',sn, 'name','modularDemo.pmFixDot', 'order',1,...
    'requestedStates', {'frameUpdate','frameDraw','frameGLDrawLeft','frameGLDrawRight','trialItiDraw','trialPrepare','experimentPreOpenScreen','experimentPostOpenScreen','experimentCleanUp'});

pss.(sn).use = true;
pss.(sn).on = true;
pss.(sn).mode = 2;          % eye position limit mode (0==pass/none, 1==square, 2==euclidean/circle)     default: 2
pss.(sn).fixPos = [0 0];    % fixation xy in vis.deg, z in cm; (z defaults to viewdist)    (%NOTE: units & usage are distinct from .display.fixPos)
pss.(sn).fixLim = fixRadius*[1 1]; % fixation window limits (x,y)  % (visual degrees; if isscalar, y==x; if mode==2, radius limit; if mode==1, box half-width limit;)
pss.(sn).dotType = 12;      % 2 = classic PTB anti-aliased dot, 3:9 = geodesic sphere (Linux-only), 10:22 3D sphere (mercurator; slow) (see help text from pmFixDot module for info on extended dotTypes available)
if pss.(sn).dotType <=2
    % pixels if classic PTB fixation dot
    pss.(sn).dotSz = 5; 
else
    % visual degrees of OpenGL dot
    pss.(sn).dotSz = 0.5; % vis. deg
end

% set this module as the active fixation module
% -- This is used to get/assign/update current .eyeX, .eyeY, .deltaXY positions
pss.pldaps.modNames.currentFix = {sn};


%% (2) base trial timing & behavioral control module
sn = 'pmBase';
pss.(sn) =  pldapsModule('modName',sn, 'name','modularDemo.pmBase', 'order',2,...);
        'requestedStates', {'frameUpdate','trialSetup','trialCleanUpandSave','experimentPreOpenScreen','experimentPostOpenScreen'});

stimDur = 3.6;
pss.(sn).stateDur = [NaN, 0.24, stimDur, NaN];


%% (10) drifting gabor module:  glDraw.pmMatrixGabs.m

% Grid sample resolution in xy dimension
gridN   = 4*[1 1]; % 7*[1 1];    %

switch stimMode
    case 'gabors'
        
        % Base params field (non-module) stores params shared across all matrixModule instances
        sn = 'gabors';
        
        if 1 % smaller grid

            % @ 5x5
            pss.(sn).stimCtr = [7, -5, 0]; % [x, y, zOffsetFromFixation]
            pss.(sn).gridSz  = 10 *[1 1];

%             % @ 7x7
%             pss.(sn).stimCtr = [6, 7, 0]; % [x, y, zOffsetFromFixation]
%             pss.(sn).gridSz  = 10 *[1 1];
            
        else % searching grid   
            % FULL Right hemifield w/ ipsillateral column
%             % @ 7x7
%             pss.(sn).stimCtr = [17, 2.5, 0]; % [x, y, zOffsetFromFixation]
%             pss.(sn).gridSz  = [40,35];  %35 *[1 1];
            
%           % MID-SIZED Lower Right hemifield w/ ipsillateral column
            % @ 7x7
            pss.(sn).stimCtr = [14.5, 7.5, 0]; % [x, y, zOffsetFromFixation]
            pss.(sn).gridSz  = [35,30];  %35 *[1 1];
            
%             % @ 9x9
%             pss.(sn).stimCtr = [15, 8.3, 0]; % [x, y, zOffsetFromFixation]
%             pss.(sn).gridSz  = [35,30];  %35 *[1 1];
                        
        end
        
        pss.(sn).gabTf = 3;
        % Gabor size: scale consistent with grid spacing
        % - set with full-width half-max parameter for best interperability
        pss.(sn).gabFwhm = max(pss.(sn).gridSz(1:2)./(gridN-1)) * 0.8;
        
        % overlay markers & mouse tracking
        pss.(sn).drawMarkers = true;
        pss.(sn).trackMouse = false; % no mouse tracking for RfPos stim
        pss.(sn).centerOnScreen = true;
        
        % *** Total stimulus duration [stimDur] set during pmBase module setup above ***
        
        tmpModule = pldapsModule('modName',sn, 'name','modularDemo.pmMatrixGabs', 'matrixModule',true, 'order',10,...
            'requestedStates', {'frameUpdate', 'framePrepareDrawing', 'frameDraw', 'trialPrepare', 'trialCleanUpandSave', 'experimentPreOpenScreen', 'experimentPostOpenScreen', 'experimentCleanUp'});
        
        % adjustments & defaults
        tmpModule.use = true;
        tmpModule.on = false;
        tmpModule.centerOnScreen = pss.(sn).centerOnScreen;
        
        % Populate shared stimulus parameters 
        tmpModule.gabContrast = 1;
        tmpModule.ngabors = 1;
        tmpModule.gabTf = pss.(sn).gabTf; % drift rate (Hz)
        tmpModule.gabFwhm = pss.(sn).gabFwhm;
        tmpModule.gabSf = 1.3/tmpModule.gabFwhm;    % V1 median bandwidth= ~1.4 (== 1.0/fwhm) --De Valois 1982
        
        % NOTE: pmMatrixGabs accepts & converts between various size params (FWHM recommended):
        %   .gabFwhm    % Full-width half-max (deg)
        %   .gabSd      % Standard deviation of gaussian hull (deg);    % gabFwhm == gabSd * sqrt(8*log(2));
        %   .gabSize    % Size of texture support rect (deg);           % 8-bit gabor==7*gabSd;

        % Parameters to be updated by condMatrix prior to each trial
        tmpModule.pos = zeros(2, tmpModule.ngabors);    
        tmpModule.dir = zeros(1, tmpModule.ngabors);
        
        % select module stimulus type
        tmpModule.type = 'cartGrid';    %'polarTrack';

        
        % Stimulus onset timing & n-reps per trial
        ncopies = 12;
        tmpModule.isi = .0;
        
        stimModuleDur = stimDur/ncopies;
        
        % Report to command window
        fprintLineBreak;
        sr = 1000;
        fprintf('\t~~~\tstimDur: %3.2fms,  isi: %3.2fms  ...x%d== %2.2fs total\n', (stimModuleDur-tmpModule.isi)*sr, tmpModule.isi*sr, ncopies, stimDur);
        fprintLineBreak;
        
    otherwise
        error('Unrecognized stimMode requested.')
        
end


% --- MATRIX MODULE SETUP ---
% Create duplicate/indexed stim modules for each repetition w/in a trial
%   - TODO: this eventually needs to be functionified, ala pldapsModule.m  --TBC
% 
matrixModNames = {};
for i = 1:ncopies
    mN = sprintf('%s%0.2d', sn, i);
    pss.(mN) = tmpModule;
    pss.(mN).stateFunction.modName = mN;
    pss.(mN).stateFunction.matrixModule = true;
    % timing: each module [onset, offset] time in sec (relative to STIMULUS state start)
    basedur = (i-1)*stimModuleDur;
    pss.(mN).modOnDur = [0, stimModuleDur-tmpModule.isi] +basedur; % subtract isi from offset
    % module names [for local use]
    matrixModNames{i} = mN;
end


%% Create PLDAPS object for this experimental session
p = pldaps(subj, pss);

% 
% LEGACY NOTE:
%   use of pdsDefaultTrialStructure.m is no longer recommended.
%       -- TBC 2020
% 


%% Define parameters of condition matrix

do3d = p.trial.display.stereoMode>0;

% Drift directions
dinc = 90; % direction increment
dirs = dinc:dinc:360; % motion directions
if do3d
    dirs = [dirs, 0,180]; % append TOWARD & AWAY (0 & 180, made bino below)
end

% Cartesian grid locations 
% - [gridN]: number of samples in xy dimension is set during the matrixModule setup code
% - grid center & span (.stimCtr & .gridSz) are parameters in gabor matrixModule base
% - final locations are computed during execution of the matrix module(s):  pmMatrixGabs.m
xs = linspace(-.5,.5, gridN(1));
ys = linspace(-.5,.5, gridN(2));

% make a fully crossed matrix
[xx, yy, dd] = ndgrid( xs, ys, dirs);

% If stereo enabled, make last two dirs comprise opposite binocular motions
is2d = numel(dd(:,:,1:end-2*do3d));


% Create cell struct of module fields to be defined by each condition
% name of pldaps module that contains experimental manipulation
% ...how could we better know/extract this when needed?
% sn = stimMode;

% Make the condMatrix!
c = cell(size(xx)); % *** maintain same shape as condition matrix source values

for i = 1:numel(xx)
    % Set up conditions
    c{i}.stimPos    = [ xx(i), yy(i)]; % stim position relative to center
    c{i}.dir    = dd(i) * ones(tmpModule.ngabors, 1+do3d); % separate dir for left & right eye
    
    if i>is2d
        % tweak 3D conditions for opposite direction
        c{i}.dir(:,2) = c{i}.dir(:,2)+180;
    end
end


%% Generate condMatrix & add to PLDAPS
p.condMatrix.conditions = c;
% 
% 'randMode' & 'nPasses' are the primary name-value pairs used to control the condMatrix:
% 
%   [nPasses]   (default: inf)
%               # of full passes through condition matrix to be completed 
%               - inf will run until experiment is manually quit ([q] key pressed)
%               - presentationw will continue until nPasses are COMPLETE,
%                 padding out the final trial with additional stimuli [from the next pass]
%                 (e.g. a 4-by-4 condition matrix with 6 stimuli per trial,
%                  nPasses=1 will comprise 4 trials, with a repeat of the first two matrix
%                  conditions; filling out the last trial.
%                 
% 
%   [randMode]  (default: 0)
%               Randomize order of upcoming pass through condition matrix
%               --Simple--
%               0 == no randomization; walk through matrix in sequential [column-major] order
%               1 == randomize across all dimensions
%               2 == randomize within columns w/ Shuffle.m
%               3 == randomize within rows (**primarily only for 2D condMatrix, 3D hacky, >3D will error)
%               --Indexed--
%               Index dimensions to be randomized:
%                 - positive randMode values will randomize each element of dimension
%                 - zero randMode values will do nothing
%                 - negative randMode values will shuffle the order of that dimension,
%                   while maintaining other dimension(s)
%                 Ex: condMatrix of [xpos, ypos, direction]
%                     - randMode [1,2,3] will have same effect as randMode [1]
%                     - randMode [1,2,-3] will present one random direction at each x,y position randomly,
%                       before advancing to a new random direction, etc, etc
%                     - randMode [3,0] will present x,y positions in order, with a different random
%                       direction at each sequential location
%                       (* here the 0 distinguishes it from simple randMode [3])
%                       

p.condMatrix = condMatrix(p, 'randMode',[1,2,3], 'nPasses',inf);
% 
% p.condMatrix = condMatrix(p, 'randMode',[2], 'nPasses',2);

% p.condMatrix = condMatrix(p, 'randMode',[3,0], 'nPasses',1);

% p.condMatrix = condMatrix(p, 'randMode',[0], 'nPasses',1);

%
% LEGACY NOTE: 
%   !! Leave p.conditions empty !! everything is in .condMatrix now
%   old-style conditions definitions should still work through PLDAPS v4.x, but
%   testing/support for that method is waining & will eventually error.
%       --TBC 2020
% 


%% Run it!!
p.run;



end
