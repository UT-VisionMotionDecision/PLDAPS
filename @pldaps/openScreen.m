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

if p.trial.display.normalizeColor == 1
    disp('****************************************************************')
    disp('****************************************************************')
    disp('Turning on Normalized High res Color Range')
    disp('Sets all displays to use color range from 0-1 (e.g. NOT 0-255),')
    disp('while also setting color range to ''unclamped''.')
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
        if isfield(p.trial.datapixx, 'rb3d') && p.trial.datapixx.rb3d==1
            disp('Using RB3d overlay window (via Datapixx VideoMode==9)')
            % No initialization phase code necessary; all done in overlay setup after window has been created.
        else
            disp('Using standard overlay window (EnableDataPixxM16OutputWithOverlay)')
            PsychImaging('AddTask', 'General', 'EnableDataPixxM16OutputWithOverlay');            
            
        end
        disp('****************************************************************')
        
    end
else
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');

end

%% Stereo specific adjustments
if isfield(p.trial.datapixx, 'rb3d') && p.trial.datapixx.rb3d==1
    % Ensure stereomode==8 (Red-Blue anaglyph) for proper assignment of L/R stereobuffers into R & B channels
   p.trial.display.stereoMode = 8;
end

if p.trial.display.stereoMode > 0
    % PTB stereo crosstalk correction
    if isfield(p.trial.display, 'crosstalk') && any(p.trial.display.crosstalk>0)
        % Crosstalk gains == [Lr Lg Lb; Rr Rg Rb]'; 
        disp('****************************************************************')
        if numel(p.trial.display.crosstalk)==2
            fprintf('Stereo Crosstalk correction implemented by custom PLDAPS shader:\n');
        else
            %   Will apply same crosstalk correction to both eyes if only one column of [RGB] gains provided
            PsychImaging('AddTask', 'LeftView',  'StereoCrosstalkReduction', 'subtractOther', p.trial.display.crosstalk(:,1));
            PsychImaging('AddTask', 'RightView', 'StereoCrosstalkReduction', 'subtractOther', p.trial.display.crosstalk(:,end));
            fprintf('Stereo Crosstalk correction implemented by PTB:\n');
        end
        fprintf('\tL-(gain*R): [')
        fprintf('%05.2f, ', p.trial.display.crosstalk(:,1).*100)
        fprintf('\b\b]%%\n')
        fprintf('\tR-(gain*L): [')
        fprintf('%05.2f, ', p.trial.display.crosstalk(:,end).*100)
        fprintf('\b\b]%%\n')
        fprintf('****************************************************************\n')
    end
    
    % Planar display setup
    if strcmp(p.trial.display.stereoFlip,'right')
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

end

%% Color correction
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
fprintf('Opening screen %d with background %s in stereo mode %d\r', p.trial.display.scrnNum, mat2str(p.trial.display.bgColor), p.trial.display.stereoMode)
disp('****************************************************************')
[ptr, winRect]=PsychImaging('OpenWindow', p.trial.display.scrnNum, p.trial.display.bgColor, p.trial.display.screenSize, [], [], p.trial.display.stereoMode, 0);
p.trial.display.ptr=ptr;
p.trial.display.winRect=winRect;

% Software overlay is half-width; adjust winRect accordingly
if p.trial.display.useOverlay==2
    p.trial.display.winRect(3)=p.trial.display.winRect(3)/2;
end

%% Set some basic variables about the display
% Compute visual angle of the display (while accounting for any stereomode splits)
if p.trial.display.stereoMode >= 6 || p.trial.display.stereoMode <=1
    p.trial.display.width = 2*atand(p.trial.display.widthcm/2/p.trial.display.viewdist);
else
    p.trial.display.width = 2*atand((p.trial.display.widthcm/4)/p.trial.display.viewdist);
end
p.trial.display.ppd = p.trial.display.winRect(3)/p.trial.display.width; % calculate pixels per degree
p.trial.display.frate = round(1/Screen('GetFlipInterval',p.trial.display.ptr));   % frame rate (in Hz)
p.trial.display.ifi=Screen('GetFlipInterval', p.trial.display.ptr);               % Inter-frame interval (frame rate in seconds)
p.trial.display.ctr = [p.trial.display.winRect(3:4),p.trial.display.winRect(3:4)]./2 - 0.5;          % Rect defining screen center
p.trial.display.info = Screen('GetWindowInfo', p.trial.display.ptr);              % Record a bunch of general display settings
[~, ~, p.trial.display.info.realBitDepth] = Screen('ReadNormalizedGammaTable', p.trial.display.ptr); % Actual bitdepth of display hardware (not merely frame buffer bpc)

%% some more
% [p]ixel dimensions
p.trial.display.pWidth=p.trial.display.winRect(3)-p.trial.display.winRect(1);
p.trial.display.pHeight=p.trial.display.winRect(4)-p.trial.display.winRect(2);
% physical [w]orld dimensions (cm)
p.trial.display.wWidth=p.trial.display.widthcm;
p.trial.display.wHeight=p.trial.display.heightcm;
% visual [d]egrees          % updated to ensure this param reflects ppd (i.e. not an independent/redundant calculation)
p.trial.display.dWidth =  p.trial.display.pWidth/p.trial.display.ppd;   
p.trial.display.dHeight = p.trial.display.pHeight/p.trial.display.ppd;
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

%% Assign overlay pointer
if p.trial.display.useOverlay==1
    if p.trial.datapixx.use
        if ~isfield(p.trial.datapixx, 'rb3d') || ~p.trial.datapixx.rb3d
            % Standard PLDAPS overlay mode.
            % Overlay infrastructure has already been created by PsychImaging, just retrieve the pointer
            p.trial.display.overlayptr = PsychImaging('GetOverlayWindow', p.trial.display.ptr); % , dv.params.bgColor);
            
        elseif p.trial.datapixx.rb3d
            % RB3d mode needs special shaders to encode overlay in the green channel
            oldColRange = Screen('ColorRange', p.trial.display.ptr, 255);
            p.trial.display.overlayptr = SetAnaglyphStereoParameters('CreateGreenOverlay', p.trial.display.ptr);
            % Put stimulus color range back how it was
            Screen('ColorRange', p.trial.display.ptr, oldColRange);
            %             p.trial.display.overlayptr = p.trial.display.ptr;
            
            % If crosstalk format is [1x2], interpret as (1)==crosstalk gain for L-gain*R, (2)==crosstalk gain for R-gain*L
            if numel(p.trial.display.crosstalk)==2
                % setup crosstalk gains, ensuring the G (overlay channel) gain is zero
                crosstalkGain = [p.trial.display.crosstalk(1), 0, p.trial.display.crosstalk(2)];
                if min(p.trial.display.bgColor) <= 0 || max(p.trial.display.bgColor) >= 1
                    sca;    error('In StereoRb3dCrosstalkReduction: Provided background clear color is not in the normalized range > 0 and < 1 as required.');
                end
                
                % Retrieve existing shader chain
                [icmShaders, icmIdString, icmConfig] = PsychColorCorrection('GetCompiledShaders', p.trial.display.ptr, 2);
                % Load StereoRb3dCrosstalkReductionShader.frag.txt from PLDAPS directory & append existing shader chain:
                shader = LoadGLSLProgramFromFiles(fullfile(p.trial.pldaps.dirs.proot, 'SupportFunctions', 'Utils', 'StereoRb3dCrosstalkReductionShader.frag'), 2, icmShaders);
                
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
        end        
    else
        warning('pldaps:openScreen', 'Datapixx Overlay requested but datapixx disabled. No Dual head overlay availiable!')
        p.trial.display.overlayptr = p.trial.display.ptr;
        
    end
elseif p.trial.display.useOverlay==2
    
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

    %% get information of current processing chain
    debuglevel = 1;
    [icmShaders, icmIdString, icmConfig] = PsychColorCorrection('GetCompiledShaders', p.trial.display.ptr, debuglevel);

            % Build panel-filter compatible shader from source:
            overlayShader = glCreateShader(GL.FRAGMENT_SHADER);
            glShaderSource(overlayShader, shSrc);
            glCompileShader(overlayShader);

            % Attach to list of shaders:
            icmShaders(end+1) = overlayShader;

    pathtopldaps=which('pldaps.m');
    p.trial.display.shader = LoadGLSLProgramFromFiles(fullfile(pathtopldaps, '..', '..', 'SupportFunctions', 'Utils', 'overlay_shader.frag'), 2, icmShaders);

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
    
    glUniform2f(glGetUniformLocation(p.trial.display.shader, 'res'), p.trial.display.pWidth*(1/sampleX), p.trial.display.pHeight);  % [partially] corrects overaly width & position on retina displays
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
    movie.ptr = Screen('CreateMovie', ptr, fullfile(movie.dir, [movie.file '.mp4']), movie.width, movie.height, movie.frameRate, movie.options);
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
