% PLDAPS uses saved files to setup the configuration for each rig. Each
% time runPLDAPS is called, it loads the rig file that is specified in the
% PLDAPS preferences using getpref('PLDAPS', 'rig'). This script can be
% used to set up all of the variable names that are needed to run PLDAPS.
% Some may not be necessary for you rig. Read them all carefully. After
% creating the dv struct for your rig, name it and save it where you want
% 
% save('fullpath\to\filename', 'dv') and then add it to the preferences
% 
% setpref('PLDAPS', 'rig', 'fullpath\to\filename')
%
% 12/2013 jly   wrote it


%% basic flags for entering trial loops 
% dv.PASS - this boolean sets whether the trial funciton listens for input or whether
%           it just loops. If turned on, the trial animation will play in full. 
dv.pass            = false; 
% dv.useDatapixxbool -  useDatapixxbool is rarely used anymore, but it acts
%                       as a flag for whether to use the datapixx for
%                       dualCLUTS or as input. You almost certainly want
%                       this set to true 
dv.useDatapixxbool = true;

% dv.useMouse   -   useMouse flags whether or not to use the mouse as input
%                   for the eye position. Useful for debugging. Should 
%                   default to false.
dv.useMouse        = false;
% dv.quit       -   quit flags which state the main runPLDAPS trial loop is
%                   in. % this is the state that iterates between run, pause, and quit (0,1,2 repectively)
%                   0 means pldaps is running. 
%                   1 means pldaps is paused. 
%                   2 means pldaps will quit and save
%                   should be set at 
dv.quit    = 0;   
% dv.j          -   j is the current trial number
dv.j       = 1;   
% dv.trial.goodtrial -  goodtrial is a counter of good trials
dv.trial.goodtrial = 0; % iterator advances after goodtrial
% dv.trial.finish    - quits automatically if goodtrial exceeds finish
dv.trial.finish  = Inf; 

% pdsKeyboardSetup sets up a structure with all the keyboard names we use.
% Fixes for things like the numpad and number keys on the top. 
dv.kb = pdsKeyboardSetup;


% depreciated
% % dv.useEyelink
% dv.useEyelink      = true;
% dv.disp.calibration  = 2.3.*[1 -1 -1 1];
% dv.dp.movav   = 5;   % number of sampling points to average for eyetrace
% dv.dp.eyebool = 1;
% dv.dp.emgbool = 0;

% Input sampling rate -- this is a number that you need to know
% PLDAPS integrates analog input with the PsychToolBox through the Datapixx
% This is the sampling rate for that input
% dv.disp.inputSamplingRate   = 240; %1e4;


%% Datapixx analog data acquisition
% Init datapixx (dp) struct for ADC acquisition:
% Datapixx can sample at arbitrarily high rates. This code
% specifies how to sample data from the buffer through datapixx.
% Set sampling rate, analog channels, buffer size.
dv.dp.srate        = 2e3;           % sampling rate
dv.dp.AdcChList    = [0 2];         % eye channels
dv.dp.nCh = length(dv.dp.AdcChList);
dv.dp.code = 0; % can be 0-3
dv.dp.AdcChListCode   = [ dv.dp.AdcChList ; dv.dp.code .* ones(1, dv.dp.nCh)]; % adding a row of codes. see DatapixxSetAdcSchedule?') for more details.
dv.dp.sstep = 1e3/dv.dp.srate;
dv.dp.maxFr = 0;
dv.dp.nBuffFr = 5e6;

%% Display parameters
% dv.disp is a structure of all the parameters needed to run
% pdsOpenScreen.m

% display           - the name of the display you are using
dv.disp.display    = 'samsung'; 	
% bgColor           - default color when opening the screen
dv.disp.bgColor    = [.5 .5 .5];
% stereoMode        -   0 for no stereo, 4 for split, 5 for cross... look up
%                       psychToolBox documentation for more info
dv.disp.stereoMode = 0;
% Screen Measurements
% measurements for pixel to degree calculations are in centimeters
dv.disp.viewdist = 57; % view distance in centimeters
dv.disp.widthcm  = 101; % width of the screen (in centimeters)
dv.disp.heightcm = 57;  % height of the screen (in centimeters)
% which screen to open. Probably should be 1 if you have two monitors
dv.disp.scrnNum     = 1; 
dv.disp.useOverlay  = 1; % use overlay for dual color look up tables
dv.disp.normalizeColor = 1; % normalize color range between 0 and 1 if using an overlay
dv.disp.stereoFlip      = []; % use stereo flip with the planar (can be 'right' or 'left' or [])
dv.disp.screenSize      = []; % set to [] for full screen

% preflip buffer exists because there is approximately a 7ms delay between
% calling the screen flip and the actual refresh on the LCD screen. For
% CRTs, this number will be much smaller 
dv.disp.preflipbuffer = 0.0071; 
% alpha blending
dv.disp.sourceFactorNew = 'GL_SRC_ALPHA';
dv.disp.destinationFactorNew = 'GL_ONE_MINUS_SRC_ALPHA';



%% Gamma
% pldaps uses a lookup table to linearize gamma on you display. 
% the only value that really matters in the gamma table is the table
% dv.disp.gamma.table should be a matrix [colorlevels x guns x ntables]
% example is [256 x 3] 

% Example using file create by the photometer
% dv.disp.gamma.file = 'lg55ATIradeonHD4870Oct2012_GAMMA.mat';   % old as of 20141216
dv.disp.gamma.file = 'samsungCave121614a_GAMMA_1.mat';           % new as of 20141216
dv.disp.gamma.location = '/Volumes/LKCLAB/MLtoolbox/Calib/G_tables/';
tmp = load(fullfile(dv.disp.gamma.location, dv.disp.gamma.file));

% there have been some discrepencies with the format of the gamma table,
% given the gamma-generating function one uses. Here are but two out of
% potentially many formats: (lnk)
if isfield(tmp, 'gamma')
    dv.disp.gamma = tmp.gamma; 
end
if isfield(tmp, 'G_table') && all(size(tmp.G_table)==[1 256])
    dv.disp.gamma = repmat(tmp.G_table(:), [1 3]);
end
    


% Example using gamma power to correct  (uncomment below)
% gamma = 2.2; % 2.2 or 1.8 are good initial guesses
% dv.disp.gamma.table = linspace(0,1,256).^(1/gamma)'*[1 1 1];


saveFile = false;

if saveFile
    fname = ['samsungCave' datestr(date,'yyyymmdd')];
    save(fullfile('~/PLDAPS/RigConfigFiles', fname), 'dv');
end








