function dv = openScreen(dv)
% ds = pdsOpenScreen(ds)
% Opens PsychImaging Window with preferences set for use with Datapixx 
% ds is the dv.disp struct in PLDAPS
% 
% required fields
% dv.defaultParameters.display.
%   stereoMode      [double] -  0 is no stereo
%   normalizeColor  [boolean] - 1 normalized color range on PTB screen
%   useOverlay      [boolean] - 1 opens datapixx overlay window
%   stereoFlip      [string]  - 'left', 'right', or [] flips one stereo
%                               image for the planar screen
%   colorclamp      [boolean] - 1 clamps color between 0 and 1
%   scrnNum         [double]  - number of screen to open
%   sourceFactorNew [string]  - see Screen Blendfunction? 
%   destinationFactorNew      - see Screen Blendfunction? 
%   widthcm
%   heightcm
%   viewdist
%   bgColor
 
% 12/12/2013 jly wrote it   Mostly taken from Init_StereoDispPI without any
%                           of the switch-case in the front for each rig.
%                           This assumes you have set up your display
%                           struct before calling.
% 01/20/2014 jly update     Updated help text and added default arguments.
%                           Created a distinct variable to separate 
%                           colorclamp and normalize color.


%moves these to the class defaults
% if ~isfield(ds, 'screenSize'),    ds.screenSize = [];         end
% if ~isfield(ds, 'stereoMode'),    ds.stereoMode = 0;          end
% if ~isfield(ds, 'bgColor'),       ds.bgColor    = [.5 .5 .5]; end
% if ~isfield(ds, 'normalizeColor'),ds.normalizeColor = 0;      end
% if ~isfield(ds, 'stereoFlip'),    ds.stereoFlip = [];         end
% if ~isfield(ds, 'colorclamp'),    ds.colorclamp = 0;          end
% if ~isfield(ds, 'widthcm'),       ds.widthcm = 63;            end
% if ~isfield(ds, 'heightcm'),      ds.heightcm = 45;           end
% if ~isfield(ds, 'viewdist'),      ds.viewdist = 57;           end

InitializeMatlabOpenGL(0,0); %second 0: debug level =0 for speed
% AssertOpenGL;
% prevent splash screen
Screen('Preference','VisualDebugLevel',3);
% Initiate Psych Imaging screen configs
PsychImaging('PrepareConfiguration');

%% Setup Psych Imaging
% Add appropriate tasks to psych imaging pipeline

% set the size of the screen 
if dv.defaultParameters.display.stereoMode >= 6 || dv.defaultParameters.display.stereoMode <=1
    dv.defaultParameters.display.width = 2*atand(dv.defaultParameters.display.widthcm/2/dv.defaultParameters.display.viewdist);
else
    dv.defaultParameters.display.width = 2*atand((dv.defaultParameters.display.widthcm/4)/dv.defaultParameters.display.viewdist);
end


if dv.defaultParameters.display.normalizeColor == 1
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Turning on Normalized High res Color Range')
    disp('Sets all displays to use color range from 0-1 (e.g. NOT 0-255)')
    disp('Potential danger: this fxn sets color range to unclamped...don''t')
    disp('know if this will cause issue. TBC 12-18-2012')
    disp('****************************************************************')
	PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange');
end


if dv.defaultParameters.display.useOverlay && dv.defaultParameters.datapixx.use
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Using overlay pointer')
    disp('Adds flags for UseDataPixx and EnableDataPixxM16OutputWithOverlay')
    disp('****************************************************************')
    % Tell PTB we are using Datapixx
    PsychImaging('AddTask', 'General', 'UseDataPixx');
    PsychImaging('AddTask', 'General', 'FloatingPoint32Bit','disableDithering',1);
    % Turn on the overlay
    PsychImaging('AddTask', 'General', 'EnableDataPixxM16OutputWithOverlay');
%     PsychImaging('AddTask', 'General', 'UseDataPixx');
else
    disp('****************************************************************')
    disp('****************************************************************')
    disp('No overlay pointer')
    disp('****************************************************************')
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');   
end


if strcmp(dv.defaultParameters.display.stereoFlip,'right');
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Setting stereo mode for use with planar')
    disp('Flipping the RIGHT monitor to be a mirror image')
    disp('****************************************************************')
    PsychImaging('AddTask', 'RightView', 'FlipHorizontal');
elseif strcmp(dv.defaultParameters.display.stereoFlip,'left')
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Setting stereo mode for use with planar')
    disp('Flipping the LEFT monitor to be a mirror image')
    disp('****************************************************************')
    PsychImaging('AddTask', 'LeftView', 'FlipHorizontal');
end

% fancy gamma table for each screen
% if 2 gamma tables
% PsychImaging('AddTask', 'LeftView', 'DisplayColorCorrection', 'LookupTable');
% PsychImaging('AddTask', 'RightView', 'DisplayColorCorrection', 'LookupTable');
% end        
disp('****************************************************************')
disp('****************************************************************')
disp('Adding DisplayColorCorrection LookUpTable to FinalFormatting')
disp('****************************************************************')
PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'LookupTable');



%% Open double-buffered onscreen window with the requested stereo mode
disp('****************************************************************')
disp('****************************************************************')
fprintf('Opening screen %d with background %02.2f in stereo mode %d\r', dv.defaultParameters.display.scrnNum, dv.defaultParameters.display.bgColor(1), dv.defaultParameters.display.stereoMode)
disp('****************************************************************')
[ptr, winRect]=PsychImaging('OpenWindow', dv.defaultParameters.display.scrnNum, dv.defaultParameters.display.bgColor, dv.defaultParameters.display.screenSize, [], [], dv.defaultParameters.display.stereoMode, 0);
dv.defaultParameters.display.ptr=ptr;
dv.defaultParameters.display.winRect=winRect;


% % Set gamma lookup table
if isField(dv.defaultParameters, 'display.gamma')
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Loading gamma correction')
    disp('****************************************************************')
    if isstruct(dv.defaultParameters.display.gamma) 
        if isfield(dv.defaultParameters.display.gamma, 'table')
            PsychColorCorrection('SetLookupTable', dv.defaultParameters.display.ptr, dv.defaultParameters.display.gamma.table, 'FinalFormatting');
        elseif isfield(dv.defaultParameters.display.gamma, 'power')
            PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
            PsychColorCorrection('SetEncodingGamma', dv.defaultParameters.display.ptr, dv.defaultParameters.display.gamma.power, 'FinalFormatting');
        end
    else
        PsychColorCorrection('SetEncodingGamma', dv.defaultParameters.display.ptr, dv.defaultParameters.display.gamma, 'FinalFormatting');
    end

end


% % This seems redundant. Is it necessary?
if dv.defaultParameters.display.colorclamp == 1
    disp('****************************************************************')
    disp('****************************************************************')
    disp('clamping color range')
    disp('****************************************************************')
    Screen('ColorRange', dv.defaultParameters.display.ptr, 1, 0);
end
 




%% Set some basic variables about the display
dv.defaultParameters.display.ppd = dv.defaultParameters.display.winRect(3)/dv.defaultParameters.display.width; % calculate pixels per degree
dv.defaultParameters.display.frate = round(1/Screen('GetFlipInterval',dv.defaultParameters.display.ptr));   % frame rate (in Hz)
dv.defaultParameters.display.ifi=Screen('GetFlipInterval', dv.defaultParameters.display.ptr);               % Inter-frame interval (frame rate in seconds)
dv.defaultParameters.display.ctr = [dv.defaultParameters.display.winRect(3:4),dv.defaultParameters.display.winRect(3:4)]./2 - 0.5;          % Rect defining screen center
dv.defaultParameters.display.info = Screen('GetWindowInfo', dv.defaultParameters.display.ptr);              % Record a bunch of general display settings

%% some more
dv.defaultParameters.display.pWidth=dv.defaultParameters.display.winRect(3)-dv.defaultParameters.display.winRect(1);
dv.defaultParameters.display.pHeight=dv.defaultParameters.display.winRect(4)-dv.defaultParameters.display.winRect(2);      
dv.defaultParameters.display.wWidth=dv.defaultParameters.display.widthcm;
dv.defaultParameters.display.wHeight=dv.defaultParameters.display.heightcm;
dv.defaultParameters.display.dWidth = atand(dv.defaultParameters.display.wWidth/2 / dv.defaultParameters.display.viewdist)*2;
dv.defaultParameters.display.dHeight = atand(dv.defaultParameters.display.wHeight/2 / dv.defaultParameters.display.viewdist)*2;
dv.defaultParameters.display.w2px=[dv.defaultParameters.display.pWidth/dv.defaultParameters.display.wWidth; dv.defaultParameters.display.pHeight/dv.defaultParameters.display.wHeight];
dv.defaultParameters.display.px2w=[dv.defaultParameters.display.wWidth/dv.defaultParameters.display.pWidth; dv.defaultParameters.display.wHeight/dv.defaultParameters.display.pHeight];


% Set screen rotation
dv.defaultParameters.display.ltheta = 0.00*pi;                                    % Screen rotation to adjust for mirrors
dv.defaultParameters.display.rtheta = -dv.defaultParameters.display.ltheta;
dv.defaultParameters.display.scr_rot = 0;                                         % Screen Rotation for opponency conditions


% Make text clean
Screen('TextFont',dv.defaultParameters.display.ptr,'Helvetica'); 
Screen('TextSize',dv.defaultParameters.display.ptr,16);
Screen('TextStyle',dv.defaultParameters.display.ptr,1);

%moved to class defaults
% if ~isfield(ds, 'sourceFactorNew')
%     ds.sourceFactorNew = GL_SRC_ALPHA;
% end
% if ~isfield(ds, 'destinationFactorNew')
%     ds.destinationFactorNew = GL_ONE_MINUS_SRC_ALPHA;
% end

% Set up alpha-blending for smooth (anti-aliased) drawing 
disp('****************************************************************')
disp('****************************************************************')
fprintf('Setting Blend Function to %s,%s\r', dv.defaultParameters.display.sourceFactorNew, dv.defaultParameters.display.destinationFactorNew);
disp('****************************************************************')
Screen('BlendFunction', dv.defaultParameters.display.ptr, dv.defaultParameters.display.sourceFactorNew, dv.defaultParameters.display.destinationFactorNew);  % alpha blending for anti-aliased dots

if dv.defaultParameters.datapixx.use %does;t really belong here, but need it before the first flip....
    Screen('LoadNormalizedGammaTable',dv.defaultParameters.display.ptr,linspace(0,1,256)'*[1, 1, 1],0);
end
dv.defaultParameters.display.t0 = Screen('Flip', dv.defaultParameters.display.ptr); 