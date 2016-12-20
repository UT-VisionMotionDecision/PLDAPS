function p = openScreen(p)
%openScreen    opens PsychImaging Window with preferences set for special
%              decives like datapixx.
%
% required fields
% p.defaultParameters.display.
%   stereoMode      [double] -  0 is no stereo
%   normalizeColor  [boolean] - 1 normalized color range on PTB screen
%   useOverlay      [double]  - 0,1,2 opens different overlay windows
%                             - 0=no overlay, 1=datapixx, 2=software
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
% 05/2015    jk  update     changed for use with version 4.1
%                           moved default parameters to the
%                           pldapsClassDefaultParameters


InitializeMatlabOpenGL(0,0); %second 0: debug level =0 for speed
% prevent splash screen
Screen('Preference','VisualDebugLevel',3);
% Initiate Psych Imaging screen configs
PsychImaging('PrepareConfiguration');

%% Setup Psych Imaging
% Add appropriate tasks to psych imaging pipeline

% set the size of the screen
if p.trial.display.stereoMode >= 6 || p.trial.display.stereoMode <=1
    p.trial.display.width = 2*atand(p.trial.display.widthcm/2/p.trial.display.viewdist);
else
    p.trial.display.width = 2*atand((p.trial.display.widthcm/4)/p.trial.display.viewdist);
end

if p.trial.display.normalizeColor == 1
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Turning on Normalized High res Color Range')
    disp('Sets all displays to use color range from 0-1 (e.g. NOT 0-255)')
    disp('Potential danger: this fxn sets color range to unclamped...don''t')
    disp('know if this will cause issue. TBC 12-18-2012')
    disp('****************************************************************')
    PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange');
end

if p.trial.datapixx.use
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Adds flags for UseDataPixx')
    disp('****************************************************************')
    % Tell PTB we are using Datapixx
    PsychImaging('AddTask', 'General', 'UseDataPixx');
    PsychImaging('AddTask', 'General', 'FloatingPoint32Bit','disableDithering',1);
    
    if p.trial.display.useOverlay==1
        % Turn on the overlay
        disp('Using overlay window (EnableDataPixxM16OutputWithOverlay)')
        disp('****************************************************************')
        PsychImaging('AddTask', 'General', 'EnableDataPixxM16OutputWithOverlay');
    end
else
%     disp('****************************************************************')
%     disp('****************************************************************')
%     disp('No overlay window')
%     disp('****************************************************************')
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
end

if strcmp(p.trial.display.stereoFlip,'right');
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Setting stereo mode for use with planar')
    disp('Flipping the RIGHT monitor to be a mirror image')
    disp('****************************************************************')
    PsychImaging('AddTask', 'RightView', 'FlipHorizontal');
elseif strcmp(p.trial.display.stereoFlip,'left')
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
disp('Adding DisplayColorCorrection to FinalFormatting')
disp('****************************************************************')
if isField(p.trial, 'display.gamma.power')
    PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
else
	PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'LookupTable');
end


%% Open double-buffered onscreen window with the requested stereo mode
disp('****************************************************************')
disp('****************************************************************')
fprintf('Opening screen %d with background %02.2f in stereo mode %d\r', p.trial.display.scrnNum, p.trial.display.bgColor(1), p.trial.display.stereoMode)
disp('****************************************************************')
[ptr, winRect]=PsychImaging('OpenWindow', p.trial.display.scrnNum, p.trial.display.bgColor, p.trial.display.screenSize, [], [], p.trial.display.stereoMode, 0);
p.trial.display.ptr=ptr;
p.trial.display.winRect=winRect;
if p.trial.display.useOverlay==2
    p.trial.display.winRect(3)=p.trial.display.winRect(3)/2;
end

%% Set some basic variables about the display
p.trial.display.ppd = p.trial.display.winRect(3)/p.trial.display.width; % calculate pixels per degree
p.trial.display.frate = round(1/Screen('GetFlipInterval',p.trial.display.ptr));   % frame rate (in Hz)
p.trial.display.ifi=Screen('GetFlipInterval', p.trial.display.ptr);               % Inter-frame interval (frame rate in seconds)
p.trial.display.ctr = [p.trial.display.winRect(3:4),p.trial.display.winRect(3:4)]./2 - 0.5;          % Rect defining screen center
p.trial.display.info = Screen('GetWindowInfo', p.trial.display.ptr);              % Record a bunch of general display settings

%% some more
p.trial.display.pWidth=p.trial.display.winRect(3)-p.trial.display.winRect(1);
p.trial.display.pHeight=p.trial.display.winRect(4)-p.trial.display.winRect(2);
p.trial.display.wWidth=p.trial.display.widthcm;
p.trial.display.wHeight=p.trial.display.heightcm;
p.trial.display.dWidth = atand(p.trial.display.wWidth/2 / p.trial.display.viewdist)*2;
p.trial.display.dHeight = atand(p.trial.display.wHeight/2 / p.trial.display.viewdist)*2;
p.trial.display.w2px=[p.trial.display.pWidth/p.trial.display.wWidth; p.trial.display.pHeight/p.trial.display.wHeight];
p.trial.display.px2w=[p.trial.display.wWidth/p.trial.display.pWidth; p.trial.display.wHeight/p.trial.display.pHeight];

% Set screen rotation
p.trial.display.ltheta = 0.00*pi;                                    % Screen rotation to adjust for mirrors
p.trial.display.rtheta = -p.trial.display.ltheta;
p.trial.display.scr_rot = 0;                                         % Screen Rotation for opponency conditions

% Make text clean
Screen('TextFont',p.trial.display.ptr,'Helvetica');
Screen('TextSize',p.trial.display.ptr,16);
Screen('TextStyle',p.trial.display.ptr,1);

%% Assign overlay pointer
if p.trial.display.useOverlay==1
    if p.trial.datapixx.use
        p.trial.display.overlayptr = PsychImaging('GetOverlayWindow', p.trial.display.ptr); % , dv.params.bgColor);
    else
        warning('pldaps:openScreen', 'Datapixx Overlay requested but datapixx disabled. No Dual head overlay availiable!')
        p.trial.display.overlayptr = p.trial.display.ptr;
    end
elseif p.trial.display.useOverlay==2
    % if using a software overlay, adjust the window size to be half
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Using software overlay window')
    disp('****************************************************************')
    Screen('ColorRange', p.trial.display.ptr, 255)
    p.trial.display.overlayptr=Screen('OpenOffscreenWindow', p.trial.display.ptr, 0, [0 0 p.trial.display.pWidth p.trial.display.pHeight], 8, 32);
    Screen('ColorRange', p.trial.display.ptr, 1);
    
    % Retrieve low-level OpenGl texture handle to the window:
    p.trial.display.overlaytex = Screen('GetOpenGLTexture', p.trial.display.ptr, p.trial.display.overlayptr);
    
    % Disable bilinear filtering on this texture - always use
    % nearest neighbour sampling to avoid interpolation artifacts
    % in color index image for clut indexing:
    glBindTexture(GL.TEXTURE_RECTANGLE_EXT, p.trial.display.overlaytex);
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
    glBindTexture(GL.TEXTURE_RECTANGLE_EXT, 0);

    %% get information of current processing chain
    debuglevel = 1;
    [icmShaders, icmIdString, icmConfig] = PsychColorCorrection('GetCompiledShaders', p.trial.display.ptr, debuglevel);

    pathtopldaps=which('pldaps.m');
    p.trial.display.shader = LoadGLSLProgramFromFiles(fullfile(pathtopldaps, '..', '..', 'SupportFunctions', 'Utils', 'overlay_shader.frag'),2,icmShaders);

    if p.trial.display.info.GLSupportsTexturesUpToBpc >= 32
        % Full 32 bits single precision float:
        p.trial.display.internalFormat = GL.LUMINANCE_FLOAT32_APPLE;
    elseif p.trial.display.info.GLSupportsTexturesUpToBpc >= 16
        % No float32 textures:
        % Choose 16 bpc float textures:
        p.trial.display.internalFormat = GL.LUMINANCE_FLOAT16_APPLE;
    else
        % No support for > 8 bpc textures at all and/or no need for
        % more than 8 bpc precision or range. Choose 8 bpc texture:
        p.trial.display.internalFormat = GL.LUMINANCE;
    end

    %create look up textures
    p.trial.display.lookupstexs=glGenTextures(2);
    %% set variables in the shader
    glUseProgram(p.trial.display.shader);
    glUniform1i(glGetUniformLocation(p.trial.display.shader,'lookup1'),3);
    glUniform1i(glGetUniformLocation(p.trial.display.shader,'lookup2'),4);

    glUniform2f(glGetUniformLocation(p.trial.display.shader, 'res'), p.trial.display.pWidth, p.trial.display.pHeight);
    bgColor=p.trial.display.bgColor;
    glUniform3f(glGetUniformLocation(p.trial.display.shader, 'transparencycolor'), bgColor(1), bgColor(2), bgColor(3));
    glUniform1i(glGetUniformLocation(p.trial.display.shader, 'overlayImage'), 1);
    glUniform1i(glGetUniformLocation(p.trial.display.shader, 'Image'), 0);
    glUseProgram(0);

    %% assign the overlay texture as the input 1 (which mapps to 'overlayImage' as set above)
    % It gets passed to the HookFunction call.
    % Input 0 is the main pointer by default.
    pString = sprintf('TEXTURERECT2D(1)=%i ', p.trial.display.overlaytex);
    pString = [pString sprintf('TEXTURERECT2D(3)=%i ', p.trial.display.lookupstexs(1))];
    pString = [pString sprintf('TEXTURERECT2D(4)=%i ', p.trial.display.lookupstexs(2))];
    
    %add information to the current processing chain
    idString = sprintf('Overlay Shader : %s', icmIdString);
    pString  = [ pString icmConfig ];
    Screen('HookFunction', p.trial.display.ptr, 'Reset', 'FinalOutputFormattingBlit');
    Screen('HookFunction', p.trial.display.ptr, 'AppendShader', 'FinalOutputFormattingBlit', idString, p.trial.display.shader, pString);
    PsychColorCorrection('ApplyPostGLSLLinkSetup', p.trial.display.ptr, 'FinalFormatting');
else
    p.trial.display.overlayptr = p.trial.display.ptr;
end

% % Set gamma lookup table
if isField(p.trial, 'display.gamma')
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Loading gamma correction')
    disp('****************************************************************')
    if isfield(p.trial.display.gamma, 'table')
        PsychColorCorrection('SetLookupTable', p.trial.display.ptr, p.trial.display.gamma.table, 'FinalFormatting');
    elseif isfield(p.trial.display.gamma, 'power')
        PsychColorCorrection('SetEncodingGamma', p.trial.display.ptr, p.trial.display.gamma.power, 'FinalFormatting');
        if isfield(p.trial.display.gamma, 'bias') &&isfield(p.trial.display.gamma, 'minL')...
           && isfield(p.trial.display.gamma, 'minL') &&  isfield(p.trial.display.gamma, 'gain')
            bias=p.trial.display.gamma.bias;
            minL=p.trial.display.gamma.minL;
            maxL=p.trial.display.gamma.maxL;
            gain=p.trial.display.gamma.gain;
            PsychColorCorrection('SetExtendedGammaParameters', p.trial.display.ptr, minL, maxL, gain, bias);
        end
    end
else
    %set a linear gamma
    PsychColorCorrection('SetLookupTable', ptr, linspace(0,1,256)'*[1, 1, 1], 'FinalFormatting');
end

% % This seems redundant. Is it necessary?
if p.trial.display.colorclamp == 1
    disp('****************************************************************')
    disp('****************************************************************')
    disp('clamping color range')
    disp('****************************************************************')
    Screen('ColorRange', p.trial.display.ptr, 1, 0);
end

%% Setup movie creation if desired
if p.trial.display.movie.create
    movie=p.trial.display.movie;
    if isempty(movie.file)
        movie.file=p.trial.session.file(1:end-4);
    end
    if isempty(movie.dir)
        movie.dir=p.trial.session.dir;
    end
    if isempty(movie.frameRate)
        movie.frameRate = p.trial.display.frate;
    end
    movie.ptr = Screen('CreateMovie', ptr, [movie.dir filesep movie.file '.avi'], movie.width,movie.height,movie.frameRate,movie.options);
    p.trial.display.movie=movie;
end

%% Set up alpha-blending for smooth (anti-aliased) drawing
disp('****************************************************************')
disp('****************************************************************')
fprintf('Setting Blend Function to %s,%s\r', p.trial.display.sourceFactorNew, p.trial.display.destinationFactorNew);
disp('****************************************************************')
Screen('BlendFunction', p.trial.display.ptr, p.trial.display.sourceFactorNew, p.trial.display.destinationFactorNew);  % alpha blending for anti-aliased dots

if p.trial.display.forceLinearGamma %does't really belong here, but need it before the first flip....
    LoadIdentityClut(p.trial.display.ptr);
end

p=defaultColors(p); % load the default CLUTs -- this is useful for opening overlay window in pds.datapixx.init
p.trial.display.t0 = Screen('Flip', p.trial.display.ptr);