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
% 2020-03-04  TBC  House cleaning


%% PTB general interface settings
% prevent splash screen
Screen('Preference', 'VisualDebugLevel',3);
Screen('Preference', 'Verbosity',2);
InitializeMatlabOpenGL(0, 0); %second 0: debug level =0 for speed, debug level=3 == "very verbose" (slow, but incl. error msgs from w/in OpenGL/mogl functions)

fprintLineBreak
disp('~~~ PTB Screen initialization ~~~')


%% Setup Psych Imaging
% Initiate Psych Imaging screen configs
PsychImaging('PrepareConfiguration');

% Add appropriate tasks to psych imaging pipeline
if p.trial.display.normalizeColor == 1
    fprintLineBreak
    disp('Normalized High res Color Range enabled')
%     disp('Sets all displays & textures to use color range from 0-1 (e.g. NOT 0-255),')
%     disp('while also setting color range to ''unclamped''.')
%     disp('****************************************************************')
    PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange', 1);
end

%% Datapixx
if p.trial.datapixx.use
%     disp('****************************************************************')    
    fprintLineBreak
    disp('Initializing display for Datapixx')
    % Tell PTB we are using Datapixx
    PsychImaging('AddTask', 'General', 'UseDataPixx');
    
    if p.trial.display.useOverlay==1 && ~p.trial.datapixx.rb3d
        % Turn on the Datapixx "M16" hardware overlay
        disp('Using Datapixx hardware overlay (EnableDataPixxM16OutputWithOverlay)')
        PsychImaging('AddTask', 'General', 'EnableDataPixxM16OutputWithOverlay');
        % This overlay implementation needs [jumbo!] 32-bit framebuffers
        framebufferResolution = 'FloatingPoint32Bit';
    else
        % Use at least 16-bit framebuffers
        framebufferResolution = 'FloatingPoint16Bit';
    end
%     disp('****************************************************************')    
else
    % 16-bit framebuffers should be more than enough (even for 10-bit displays).
    framebufferResolution = 'FloatingPoint16Bit';
end
% Request appropriate framebuffer resolution & always disable dithering
PsychImaging('AddTask', 'General', framebufferResolution, 'disableDithering',1);
        

%% Stereo specific adjustments

p.trial.display.bufferIdx = 0; % basic/monocular Screen buffer index;

if p.trial.display.stereoMode > 0
    fprintLineBreak
    if p.trial.datapixx.use && p.trial.datapixx.rb3d
        fprintf('Stereomode enabled using Datapixx RB3D\n');
        % Ensure stereomode==8 (Red-Blue anaglyph) for proper assignment of L/R stereobuffers into R & B channels
        p.trial.display.stereoMode = 8;
    else
        fprintf('Stereomode %d enabled\n', p.trial.display.stereoMode);
    end

    % Append buffer index for right eye
    p.trial.display.bufferIdx(end+1) = p.trial.display.bufferIdx(end)+1; 

    % PTB stereo crosstalk correction
    if isfield(p.trial.display, 'crosstalk') && any(p.trial.display.crosstalk(:))
        % Crosstalk gains == [Lr Lg Lb; Rr Rg Rb]'; 
        %disp('****************************************************************')
        if numel(p.trial.display.crosstalk)==2
            fprintf('Stereo Crosstalk correction implemented by custom PLDAPS shader:\n');
        else
            %   Will apply same crosstalk correction to both eyes if only one column of [RGB] gains provided
            PsychImaging('AddTask', 'LeftView',  'StereoCrosstalkReduction', 'subtractOther', p.trial.display.crosstalk(:,1));
            PsychImaging('AddTask', 'RightView', 'StereoCrosstalkReduction', 'subtractOther', p.trial.display.crosstalk(:,end));
            fprintf('Stereo Crosstalk correction implemented by PTB:\n');
        end
        % Crosstalk gain can be scalar or 3-element RGB array of gains for each eye (...thus funky formatting below)
        fprintf('\tL-(gain*R): [')
        fprintf('%05.2f, ', p.trial.display.crosstalk(:,1).*100)
        fprintf('\b\b]%%\n')
        fprintf('\tR-(gain*L): [')
        fprintf('%05.2f, ', p.trial.display.crosstalk(:,end).*100)
        fprintf('\b\b]%%\n')
        %fprintf('****************************************************************\n')
    end
    
    % Planar display setup
    if strcmp(p.trial.display.stereoFlip,'right')
        disp('****************************************************************')
        disp('Setting stereo mode for use with planar')
        disp('Flipping the RIGHT monitor to be a mirror image')
        disp('****************************************************************')
        PsychImaging('AddTask', 'RightView', 'FlipHorizontal');
    elseif strcmp(p.trial.display.stereoFlip,'left')
        disp('****************************************************************')
        disp('Setting stereo mode for use with planar')
        disp('Flipping the LEFT monitor to be a mirror image')
        disp('****************************************************************')
        PsychImaging('AddTask', 'LeftView', 'FlipHorizontal');
    end

end


%% Color correction
% Must be initialized before PTB screen opened, correction parameters are loaded/applied below
if isField(p.trial, 'display.gamma.power')
    PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'SimpleGamma');
else
	PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'LookupTable');
end

% Functional modifications to PsychImaging prior to PTB screen creation
%   [p.trial.display.preOpenScreenFxn]
%   --  e.g. for demo generation or coding on a hiDPI laptop (e.g. macbook pro, etc), set rigpref for:
%       .display.preOpenScreenFxn = sprintf('PsychImaging(''AddTask'', ''General'', ''UseRetinaResolution'');');
% ~!~WARNING~!~
%   Function handles in p.trial will sow havoc in the 'params class' hierarchy...
%   Don't use until params class usage has been properly fixed/removed --TBC Mar 2020
if ~isempty(p.trial.display.preOpenScreenFxn)
    if ishandle(p.trial.display.preOpenScreenFxn)
        % eval as function handle
        feval(p.trial.display.preOpenScreenFxn);
    elseif ischar(p.trial.display.preOpenScreenFxn)
        % eval as string
        eval(p.trial.display.preOpenScreenFxn);
    else
        fprintf(2, '~!~\tUnable to execute p.trial.display.preOpenScreenFxn\n')
    end
end


%% Open double-buffered onscreen window with the requested stereo mode
disp('****************************************************************')
fprintf('Opening screen %d with background %s in stereo mode %d\r', p.trial.display.scrnNum, mat2str(p.trial.display.bgColor), p.trial.display.stereoMode)
disp('****************************************************************')
[ptr, winRect] = PsychImaging('OpenWindow', p.trial.display.scrnNum, p.trial.display.bgColor, p.trial.display.screenSize, [], [], p.trial.display.stereoMode, p.trial.display.multisample);
p.trial.display.ptr = ptr;
p.trial.display.winRect = winRect;


% % % [p.trial.display.postOpenScreenFxn]
% Functional modifications to PsychImaging prior to PTB screen creation
%   --  e.g. for demo generation or coding on a hiDPI laptop (e.g. macbook pro, etc), set rigpref for:
%       .display.preOpenScreenFxn = sprintf('PsychImaging(''AddTask'', ''General'', ''UseRetinaResolution'');');
% ~!~WARNING~!~
%   Function handles in p.trial will sow havoc in the 'params class' hierarchy...
%   Don't use until params class usage has been properly fixed/removed --TBC Mar 2020
if ~isempty(p.trial.display.postOpenScreenFxn)
    if ishandle(p.trial.display.postOpenScreenFxn)
        % eval as function handle
        feval(p.trial.display.postOpenScreenFxn);
    elseif ischar(p.trial.display.postOpenScreenFxn)
        % eval as string
        eval(p.trial.display.postOpenScreenFxn);
    else
        fprintf(2, '~!~\tUnable to execute p.trial.display.postOpenScreenFxn\n')
    end
end

if p.trial.display.stereoMode > 0
    % Ensure initialized to consistent stereo buffer
    Screen('SelectStereoDrawBuffer', p.trial.display.ptr, p.trial.display.bufferIdx(1));
end

%% Retrieve/calculate some basic variables about the display

% % Adjust display for special circumstances (e.g. stereomodes, or custom software overlays)
% Software overlay takes over right half of screen (...ideally a single PTB window spanning two displays with equal spatiotemporal res)
% Adjust winRect accordingly
if p.trial.display.useOverlay==2
    p.trial.display.winRect(3) = p.trial.display.winRect(3)/2;
end

% physical [w]orld dimensions (cm)
if p.trial.display.stereoMode >= 2 && p.trial.display.stereoMode <=5
    % Adjust for half-width stereo display  (...distinct from above correction, where in winRect is already halved)
    p.trial.display.wWidth=p.trial.display.widthcm/2;
else
    p.trial.display.wWidth=p.trial.display.widthcm;
end
p.trial.display.wHeight=p.trial.display.heightcm;

% Compute visual angle of the display (while accounting for any stereomode splits)
switch p.trial.display.stereoMode
    case {2,3}
        % top-bottom split stereo
        p.trial.display.width   = 2*atand( p.trial.display.widthcm/2    /p.trial.display.viewdist);
        p.trial.display.height  = 2*atand( p.trial.display.heightcm/4   /p.trial.display.viewdist);
    case {4,5}
        % left-right split stereo
        p.trial.display.width   = 2*atand( p.trial.display.widthcm/4    /p.trial.display.viewdist);
        p.trial.display.height  = 2*atand( p.trial.display.heightcm/2   /p.trial.display.viewdist);
    otherwise
        p.trial.display.width   = 2*atand( p.trial.display.widthcm/2    /p.trial.display.viewdist);
        p.trial.display.height  = 2*atand( p.trial.display.heightcm/2   /p.trial.display.viewdist);
end

p.trial.display.ppd = p.trial.display.winRect(4)/p.trial.display.height; % calculate pixels per degree
p.trial.display.cmpd = 2*atand(0.5/p.trial.display.viewdist); % cm per degree at viewing distance line of sight
p.trial.display.frate = round(1/Screen('GetFlipInterval',p.trial.display.ptr));   % frame rate (in Hz)
p.trial.display.ifi=Screen('GetFlipInterval', p.trial.display.ptr);               % Inter-frame interval (frame rate in seconds)

p.trial.display.ctr = [p.trial.display.winRect(3:4), p.trial.display.winRect(3:4)]./2 - 0.5;          % Rect defining screen center
p.trial.display.info = Screen('GetWindowInfo', p.trial.display.ptr);              % Record a bunch of general display settings
[~, ~, p.trial.display.info.realBitDepth] = Screen('ReadNormalizedGammaTable', p.trial.display.ptr); % Actual bitdepth of display hardware (not merely frame buffer bpc)


% [p]ixel dimensions
p.trial.display.pWidth=p.trial.display.winRect(3)-p.trial.display.winRect(1);
p.trial.display.pHeight=p.trial.display.winRect(4)-p.trial.display.winRect(2);

% visual [d]egrees          % fixing redundancy with original .width & .height (prev calc [re]introduced error due to small angle approximation)
p.trial.display.dWidth =  p.trial.display.width;    % p.trial.display.pWidth/p.trial.display.ppd;   
p.trial.display.dHeight = p.trial.display.height;   % p.trial.display.pHeight/p.trial.display.ppd;

% space conversions
p.trial.display.w2px=[p.trial.display.pWidth/p.trial.display.wWidth; p.trial.display.pHeight/p.trial.display.wHeight];
p.trial.display.px2w=[p.trial.display.wWidth/p.trial.display.pWidth; p.trial.display.wHeight/p.trial.display.pHeight];

% Set screen rotation
p.trial.display.ltheta = 0.00*pi;                                    % Screen rotation to adjust for mirrors
p.trial.display.rtheta = -p.trial.display.ltheta;
p.trial.display.scr_rot = 0;                                         

% Make text clean
Screen('TextFont',p.trial.display.ptr,'Helvetica');
Screen('TextSize',p.trial.display.ptr,16);
Screen('TextStyle',p.trial.display.ptr,1);


%% Overlay selection & creation
if p.trial.display.useOverlay==1
    %% 'Standard' PLDAPS Overlay creation
    % Prevent text antialiasing from causing overlay to bleed over into subject display
    Screen('Preference', 'TextAntiAliasing', 0);
    
    if p.trial.datapixx.use
        if ~isfield(p.trial.datapixx, 'rb3d') || ~p.trial.datapixx.rb3d
            % Standard PLDAPS overlay mode.
            % Overlay infrastructure has already been created by PsychImaging, just retrieve the pointer
            p.trial.display.overlayptr = PsychImaging('GetOverlayWindow', p.trial.display.ptr); % , dv.params.bgColor);
            
        elseif p.trial.datapixx.rb3d
            % RB3d mode needs special shaders to encode overlay in the green channel
            oldColRange = Screen('ColorRange', p.trial.display.ptr, 255);
            %             p.trial.display.overlayptr = SetAnaglyphStereoParameters('CreateGreenOverlay', p.trial.display.ptr);
            % Manually create overlay window so we can make tweaks to setup performed by SetAnaglyphStereoParameters
            glUseProgram(0);
            p.trial.display.overlayptr = Screen('OpenOffscreenWindow', p.trial.display.ptr, 0, [0 0 p.trial.display.pWidth p.trial.display.pHeight], 8, 32);            
            % Put stimulus color range back how it was
            Screen('ColorRange', p.trial.display.ptr, oldColRange);
            
            p.trial.display.overlaytex = Screen('GetOpenGLTexture', p.trial.display.ptr, p.trial.display.overlayptr);
            % Super cryptic copy-pasta from SetAnaglyphStereoParameters('CreateGreenOverlay'...)
            Screen('Hookfunction', p.trial.display.ptr, 'AppendMFunction', 'StereoCompositingBlit', 'Setup1 Green only mask for Overlay', 'glColorMask(0, 1, 0, 0);');
            Screen('Hookfunction', p.trial.display.ptr, 'AppendMFunction', 'StereoCompositingBlit', 'Setup2 Texunit1 off for Overlay', 'glActiveTexture(33985);');
            Screen('Hookfunction', p.trial.display.ptr, 'AppendMFunction', 'StereoCompositingBlit', 'Setup3 Texunit1 off for Overlay', 'glDisable(34037);');
            Screen('Hookfunction', p.trial.display.ptr, 'AppendMFunction', 'StereoCompositingBlit', 'Setup4 Texunit1 off for Overlay', 'glActiveTexture(33984);');
            Screen('Hookfunction', p.trial.display.ptr, 'AppendBuiltin',   'StereoCompositingBlit', 'Builtin:IdentityBlit', sprintf('TEXTURERECT2D(0)=%i', p.trial.display.overlaytex));
            Screen('Hookfunction', p.trial.display.ptr, 'AppendMFunction', 'StereoCompositingBlit', 'Reset colormask after Overlay blit', 'glColorMask(1, 1, 1, 1);');
            
            % Disable bilinear filtering on this texture - always use nearest neighbour sampling to avoid interpolation artifacts
            glBindTexture(GL.TEXTURE_RECTANGLE_EXT, p.trial.display.overlaytex);
            glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
            glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
            glBindTexture(GL.TEXTURE_RECTANGLE_EXT, 0);

        end
    else
        warning('pldaps:openScreen', 'Datapixx Overlay requested but datapixx disabled. No Dual head overlay availiable!')
        p.trial.display.overlayptr = p.trial.display.ptr;
        
    end
elseif p.trial.display.useOverlay==2
    %% "Software" Overlay creation
            % Create additional shader for overlay texel fetch:
            % Our gpu panel scaler might be active, so the size of the
            % virtual window - and thereby our overlay window - can be
            % different from the output framebuffer size. As the sampling
            % 'pos'ition for the overlay is always provided in framebuffer
            % coordinates, we need to subsample in the overlay fetch.
            % Calculate proper scaling factor, based on virtual and real
            % framebuffer size:
            [wC, hC] = Screen('WindowSize', p.trial.display.ptr);
            [wF, hF] = Screen('WindowSize', p.trial.display.ptr, 1);
            sampleX =  wC / wF;
            sampleY = hC / hF;
            
            % String definition of overlay panel-filter index shader
            % (...for dealing with retina resolution displays; solution carried over from BitsPlusPlus.m)
            shSrc = sprintf('uniform sampler2DRect overlayImage; float getMonoOverlayIndex(vec2 pos) { return(texture2DRect(overlayImage, pos * vec2(%f, %f)).r); }', sampleX, sampleY);

    % if using a software overlay, the window size needs to [already] be halved.
    disp('****************************************************************')
    disp('Using software overlay window')
    disp('****************************************************************')
	oldColRange = Screen('ColorRange', p.trial.display.ptr, 255);
    p.trial.display.overlayptr=Screen('OpenOffscreenWindow', p.trial.display.ptr, 0, [0 0 p.trial.display.pWidth p.trial.display.pHeight], 8, 32);
    % Put stimulus color range back how it was
    Screen('ColorRange', p.trial.display.ptr, oldColRange);
    
    % Retrieve low-level OpenGl texture handle to the window:
    p.trial.display.overlaytex = Screen('GetOpenGLTexture', p.trial.display.ptr, p.trial.display.overlayptr);
    
    % Disable bilinear filtering on this texture - always use
    % nearest neighbour sampling to avoid interpolation artifacts
    % in color index image for clut indexing:
    glBindTexture(GL.TEXTURE_RECTANGLE_EXT, p.trial.display.overlaytex);
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
    glTexParameteri(GL.TEXTURE_RECTANGLE_EXT, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
    glBindTexture(GL.TEXTURE_RECTANGLE_EXT, 0);

    % get information of current processing chain
    debuglevel = 0;
    [icmShaders, icmIdString, icmConfig] = PsychColorCorrection('GetCompiledShaders', p.trial.display.ptr, debuglevel);

            % Build panel-filter compatible shader from source:
            overlayShader = glCreateShader(GL.FRAGMENT_SHADER);
            glShaderSource(overlayShader, shSrc);
            glCompileShader(overlayShader);

            % Attach to list of shaders:
            icmShaders(end+1) = overlayShader;

    p.trial.display.shader = LoadGLSLProgramFromFiles(fullfile(p.trial.pldaps.dirs.proot, 'SupportFunctions', 'Utils', 'overlay_shader.frag'), debuglevel, icmShaders);
    % Incremement overlay window index to allow for stereo buffer creation (buffer object indexing --e.g. onscreen & overlay windows-- starts at 0)
    p.trial.display.overlayShaderIdx = 0+length(p.trial.display.bufferIdx);

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

    % Create look up textures
    p.trial.display.lookupstexs=glGenTextures(2);
    
    % set variables in the shader
    glUseProgram(p.trial.display.shader);
    glUniform1i(glGetUniformLocation(p.trial.display.shader,'lookup1'),3);
    glUniform1i(glGetUniformLocation(p.trial.display.shader,'lookup2'),4);
    
    glUniform2f(glGetUniformLocation(p.trial.display.shader, 'res'), p.trial.display.pWidth*(1/sampleX), p.trial.display.pHeight);  % [partially] corrects overaly width & position on retina displays
    bgColor=p.trial.display.bgColor;
    glUniform3f(glGetUniformLocation(p.trial.display.shader, 'transparencycolor'), bgColor(1), bgColor(2), bgColor(3));
    glUniform1i(glGetUniformLocation(p.trial.display.shader, 'overlayImage'), p.trial.display.overlayShaderIdx);
    glUniform1i(glGetUniformLocation(p.trial.display.shader, 'Image'), 0);
    glUseProgram(0);

    % Assign the overlay texture as the input 1 (which mapps to 'overlayImage' as set above)
    % It gets passed to the HookFunction call.
    % Input 0 is the main pointer by default.
    pString = sprintf('TEXTURERECT2D(%i)=%i ', p.trial.display.overlayShaderIdx, p.trial.display.overlaytex);
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


%% Apply display calibration (e.g. gamma encoding or lookup table)
if isField(p.trial, 'display.gamma')
    % disp('****************************************************************')
    fprintLineBreak
    fprintf('Applying display color correction ');
    if isfield(p.trial.display.gamma, 'table')
        fprintf('via lookup table\n');
        PsychColorCorrection('SetLookupTable', p.trial.display.ptr, p.trial.display.gamma.table, 'FinalFormatting');
    elseif isfield(p.trial.display.gamma, 'power')
        fprintf('via gamma power %3.3f\n', p.trial.display.gamma.power);
        PsychColorCorrection('SetEncodingGamma', p.trial.display.ptr, p.trial.display.gamma.power, 'FinalFormatting');
        % Extended gamma parameters
        if all( isfield(p.trial.display.gamma, {'bias', 'minL', 'maxL', 'gain'}) )
            bias=p.trial.display.gamma.bias;
            minL=p.trial.display.gamma.minL;
            maxL=p.trial.display.gamma.maxL;
            gain=p.trial.display.gamma.gain;
            PsychColorCorrection('SetExtendedGammaParameters', p.trial.display.ptr, minL, maxL, gain, bias);
        end
    end
else
    %set a linear gamma
    PsychColorCorrection('SetLookupTable', ptr, linspace(0,1,p.trial.display.info.realBitDepth)'*[1, 1, 1], 'FinalFormatting');
end

% % This seems redundant. Is it necessary?
if p.trial.display.colorclamp == 1
    %disp('****************************************************************')
    disp('clamping color range [0:1]')
    %disp('****************************************************************')
    Screen('ColorRange', p.trial.display.ptr, 1, 0);
end


%% Rb3d stereo crosstalk correction
%   -- This custom crosstalk correction shader is fine tuned for ProPixx Rb3d mode, and mmmuch faster than basic version built into PTB
%   -- [p.trial.display.crosstalk] format must be [1x2];
%      will be interpreted as (1)==crosstalk gain for L-gain*R, (2)==crosstalk gain for R-gain*L
if p.trial.datapixx.rb3d &&  numel(p.trial.display.crosstalk)==2
    % setup crosstalk gains, ensuring the G (overlay channel) gain is zero
    crosstalkGain = [p.trial.display.crosstalk(1), 0, p.trial.display.crosstalk(2)];
    if min(p.trial.display.bgColor) <= 0 || max(p.trial.display.bgColor) >= 1
        sca;    error('In StereoRb3dCrosstalkReduction: Provided background clear color is not in the normalized range > 0 and < 1 as required.');
    end
    
    % Retrieve existing shader chain
    [icmShaders, icmIdString, icmConfig] = PsychColorCorrection('GetCompiledShaders', p.trial.display.ptr, 0);
    % Load StereoRb3dCrosstalkReductionShader.frag.txt from PLDAPS directory & append existing shader chain:
    shader = LoadGLSLProgramFromFiles(fullfile(p.trial.pldaps.dirs.proot, 'SupportFunctions', 'Utils', 'StereoRb3dCrosstalkReductionShader.frag'), 0, icmShaders);
    
    % Init the shader: Assign mapping of shader inputs:
    glUseProgram(shader);
    % [Image] will contain the finalized image (after L & R streams have been blitted into R & B channels, respectively)
    glUniform1i(glGetUniformLocation(shader, 'Image'), 0);
    % Pass crosstalk gain & background color triplets into shader
    glUniform3fv(glGetUniformLocation(shader, 'crosstalkGain'), 1, crosstalkGain);
    glUniform3fv(glGetUniformLocation(shader, 'backGroundClr'), 1, p.trial.display.bgColor);
    % Shader setup done:
    glUseProgram(0);
    
    p.trial.display.crosstalkShader = shader;
    % Apply to the FinalOutputFormattingBlit
    idString = sprintf('Crosstalk Shader : %s', icmIdString);
    % pString  = [ pString icmConfig ]; ...no additional textureRect2Ds to map
    Screen('HookFunction', p.trial.display.ptr, 'Reset', 'FinalOutputFormattingBlit');
    Screen('HookFunction', p.trial.display.ptr, 'AppendShader', 'FinalOutputFormattingBlit', idString, p.trial.display.crosstalkShader, icmConfig);
    PsychColorCorrection('ApplyPostGLSLLinkSetup', p.trial.display.ptr, 'FinalFormatting');
end


%% Setup OpenGL blend functions
%   --  e.g. for smooth (anti-aliased) dot rendering, use alpha-blending:
%       Screen('BlendFunction', p.trial.display.ptr, 'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');
disp('****************************************************************')
fprintf('Setting Blend Function to %s,%s\r', p.trial.display.sourceFactorNew, p.trial.display.destinationFactorNew);
disp('****************************************************************')
Screen('BlendFunction', p.trial.display.ptr, p.trial.display.sourceFactorNew, p.trial.display.destinationFactorNew);  % alpha blending for anti-aliased dots

if p.trial.display.forceLinearGamma %does't really belong here, but need it before the first flip....
    LoadIdentityClut(p.trial.display.ptr);
end


%% Setup cluts & basic colors
p = defaultColors(p); % load the default CLUTs -- this is useful for opening overlay window in pds.datapixx.init
p.trial.display.white = WhiteIndex(p.trial.display.ptr);
p.trial.display.black = BlackIndex(p.trial.display.ptr);


%% Establish p.static display parameters
% Isn't/shouldn't be entire .display struct, but core elements that are needed
% for comparison (like physical distance) across experimental trials
p.static.display.viewdist = p.trial.display.viewdist;


%% Flip screen to get initial timestamp & finish
p.trial.display.t0 = Screen('Flip', p.trial.display.ptr);


