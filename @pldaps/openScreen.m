function p = openScreen(p)
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
if p.defaultParameters.display.stereoMode >= 6 || p.defaultParameters.display.stereoMode <=1
    p.defaultParameters.display.width = 2*atand(p.defaultParameters.display.widthcm/2/p.defaultParameters.display.viewdist);
else
    p.defaultParameters.display.width = 2*atand((p.defaultParameters.display.widthcm/4)/p.defaultParameters.display.viewdist);
end


if p.defaultParameters.display.normalizeColor == 1
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Turning on Normalized High res Color Range')
    disp('Sets all displays to use color range from 0-1 (e.g. NOT 0-255)')
    disp('Potential danger: this fxn sets color range to unclamped...don''t')
    disp('know if this will cause issue. TBC 12-18-2012')
    disp('****************************************************************')
	PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange');
end


if p.defaultParameters.display.useOverlay && p.defaultParameters.datapixx.use
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


if strcmp(p.defaultParameters.display.stereoFlip,'right');
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Setting stereo mode for use with planar')
    disp('Flipping the RIGHT monitor to be a mirror image')
    disp('****************************************************************')
    PsychImaging('AddTask', 'RightView', 'FlipHorizontal');
elseif strcmp(p.defaultParameters.display.stereoFlip,'left')
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
fprintf('Opening screen %d with background %02.2f in stereo mode %d\r', p.defaultParameters.display.scrnNum, p.defaultParameters.display.bgColor(1), p.defaultParameters.display.stereoMode)
disp('****************************************************************')
[ptr, winRect]=PsychImaging('OpenWindow', p.defaultParameters.display.scrnNum, p.defaultParameters.display.bgColor, p.defaultParameters.display.screenSize, [], [], p.defaultParameters.display.stereoMode, 0);
p.defaultParameters.display.ptr=ptr;
p.defaultParameters.display.winRect=winRect;

% % Set gamma lookup table
if isField(p.defaultParameters, 'display.gamma')
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Loading gamma correction')
    disp('****************************************************************')
    if isstruct(p.defaultParameters.display.gamma) 
        if isfield(p.defaultParameters.display.gamma, 'table')
            PsychColorCorrection('SetLookupTable', p.defaultParameters.display.ptr, p.defaultParameters.display.gamma.table, 'FinalFormatting');
        elseif isfield(p.defaultParameters.display.gamma, 'power')
            PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
            PsychColorCorrection('SetEncodingGamma', p.defaultParameters.display.ptr, p.defaultParameters.display.gamma.power, 'FinalFormatting');
        end
    else
        PsychColorCorrection('SetEncodingGamma', p.defaultParameters.display.ptr, p.defaultParameters.display.gamma, 'FinalFormatting');
    end
else
    %set a linear gamma
    PsychColorCorrection('SetLookupTable', ptr, linspace(0,1,256)'*[1, 1, 1], 'FinalFormatting');
end


% % This seems redundant. Is it necessary?
if p.defaultParameters.display.colorclamp == 1
    disp('****************************************************************')
    disp('****************************************************************')
    disp('clamping color range')
    disp('****************************************************************')
    Screen('ColorRange', p.defaultParameters.display.ptr, 1, 0);
end
 




%% Set some basic variables about the display
p.defaultParameters.display.ppd = p.defaultParameters.display.winRect(3)/p.defaultParameters.display.width; % calculate pixels per degree
p.defaultParameters.display.frate = round(1/Screen('GetFlipInterval',p.defaultParameters.display.ptr));   % frame rate (in Hz)
p.defaultParameters.display.ifi=Screen('GetFlipInterval', p.defaultParameters.display.ptr);               % Inter-frame interval (frame rate in seconds)
p.defaultParameters.display.ctr = [p.defaultParameters.display.winRect(3:4),p.defaultParameters.display.winRect(3:4)]./2 - 0.5;          % Rect defining screen center
p.defaultParameters.display.info = Screen('GetWindowInfo', p.defaultParameters.display.ptr);              % Record a bunch of general display settings

%% some more
p.defaultParameters.display.pWidth=p.defaultParameters.display.winRect(3)-p.defaultParameters.display.winRect(1);
p.defaultParameters.display.pHeight=p.defaultParameters.display.winRect(4)-p.defaultParameters.display.winRect(2);      
p.defaultParameters.display.wWidth=p.defaultParameters.display.widthcm;
p.defaultParameters.display.wHeight=p.defaultParameters.display.heightcm;
p.defaultParameters.display.dWidth = atand(p.defaultParameters.display.wWidth/2 / p.defaultParameters.display.viewdist)*2;
p.defaultParameters.display.dHeight = atand(p.defaultParameters.display.wHeight/2 / p.defaultParameters.display.viewdist)*2;
p.defaultParameters.display.w2px=[p.defaultParameters.display.pWidth/p.defaultParameters.display.wWidth; p.defaultParameters.display.pHeight/p.defaultParameters.display.wHeight];
p.defaultParameters.display.px2w=[p.defaultParameters.display.wWidth/p.defaultParameters.display.pWidth; p.defaultParameters.display.wHeight/p.defaultParameters.display.pHeight];


% Set screen rotation
p.defaultParameters.display.ltheta = 0.00*pi;                                    % Screen rotation to adjust for mirrors
p.defaultParameters.display.rtheta = -p.defaultParameters.display.ltheta;
p.defaultParameters.display.scr_rot = 0;                                         % Screen Rotation for opponency conditions


% Make text clean
Screen('TextFont',p.defaultParameters.display.ptr,'Helvetica'); 
Screen('TextSize',p.defaultParameters.display.ptr,16);
Screen('TextStyle',p.defaultParameters.display.ptr,1);

%%setup movie creation if desired
if p.defaultParameters.display.movie.create
    movie=p.defaultParameters.display.movie;
    if isempty(movie.file)
        movie.file=p.defaultParameters.session.file(1:end-4);
    end
    if isempty(movie.dir)
        movie.dir=p.defaultParameters.session.dir;
    end
    if isempty(movie.frameRate)
        movie.frameRate = p.defaultParameters.display.frate;
    end
    movie.ptr = Screen('CreateMovie', ptr, [movie.dir filesep movie.file '.avi'], movie.width,movie.height,movie.frameRate,movie.options);
    p.defaultParameters.display.movie=movie;
end


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
fprintf('Setting Blend Function to %s,%s\r', p.defaultParameters.display.sourceFactorNew, p.defaultParameters.display.destinationFactorNew);
disp('****************************************************************')
Screen('BlendFunction', p.defaultParameters.display.ptr, p.defaultParameters.display.sourceFactorNew, p.defaultParameters.display.destinationFactorNew);  % alpha blending for anti-aliased dots

if p.trial.display.forceLinearGamma %does't really belong here, but need it before the first flip....
    Screen('LoadNormalizedGammaTable',p.defaultParameters.display.ptr,linspace(0,1,256)'*[1, 1, 1],0);
end
p.defaultParameters.display.t0 = Screen('Flip', p.defaultParameters.display.ptr); 