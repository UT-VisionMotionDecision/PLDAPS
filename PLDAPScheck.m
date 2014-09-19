% PLDAPS M16 Double CLUT test with simple gamma correction
% open PsychImaging pipeline and test all PLDAPS features
% (c) jly 9.18.2012 heavily based on code from Peter April of VPixx
sca; clear all
skipPdsOpenScreen    = 1;
skipPdsDatapixxInit  = 1;
skipMakeGaborTexture = 1;

%% Initial setup

dv.disp.scrnNum=max(Screen('Screens'));
dv.disp.bgColor = [.5 .5 .5];
dv.disp.gamma.table = linspace(0,1, 256)'*[1 1 1];
% extra for checking pdsOpenScreen
dv.disp.stereoMode  =0;
dv.disp.normalizeColor = 0; % normalized color range on PTB screen
dv.disp.useOverlay = 1; % opens datapixx overlay window
dv.disp.stereoFlip = []; % 'left', 'right', or [] flips one stereo image for the planar screen
dv.disp.colorclamp = 0; % clamps color between 0 and 1
dv.disp.sourceFactorNew = GL_ONE;
dv.disp.destinationFactorNew = GL_ONE;
dv.disp.widthcm = 100;
dv.disp.heightcm = 60;
dv.disp.viewdist = 57;
dv.useDatapixxbool = 1;


if skipPdsOpenScreen
    AssertOpenGL;
    
    % prevent splash screen
    Screen('Preference','VisualDebugLevel',3);
    
    % Initiate PI screen configs
    PsychImaging('PrepareConfiguration');
    
    % TBC added commands in Init_SterepDispPI -- not necessary to run Datapixx
    % dual CLUT
    % PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange');
    PsychImaging('AddTask', 'General', 'UseDataPixx');
    
    
    % PsychImaging('AddTask', 'General', 'UseDataPixx');
    PsychImaging('AddTask', 'General', 'FloatingPoint32Bit');
    PsychImaging('AddTask', 'General', 'EnableDataPixxM16OutputWithOverlay');
    % PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection',
    % 'SimpleGamma');
    PsychImaging('AddTask', 'FinalFormatting', 'DisplayColorCorrection', 'LookupTable');
    
    
    %% Open Window
    % Assume that the DATAPixx is connected to the highest number screen.
    
    % Open window using PsychImaging pipeline
    
    [dv.disp.ptr, dv.disp.winRect] = PsychImaging('OpenWindow', dv.disp.scrnNum, dv.disp.bgColor);%, [], [], [], 0, 0, [],'kPsychNeedFastBackingStore');
    
    %% Gamma Correction
    % make a linear gamma table to test gamma corection
    
    PsychColorCorrection('SetLookupTable', dv.disp.ptr, dv.disp.gamma.table, 'FinalFormatting');
    
    % Screen('ColorRange', win, 1, 0)
    
    Screen('BlendFunction', dv.disp.ptr, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');  % alpha blending for anti-aliased dots
    
else
    dv.disp = pdsOpenScreen(dv.disp);
end


%% Init Datapixx
dv.disp.humanCLUT  = linspace(0, 1, 256)' * [0, 1, 0];
dv.disp.monkeyCLUT = linspace(0, 1, 256)' * [1, 0, 0];

if skipPdsDatapixxInit
    % Screen('LoadNormalizedGammaTable', win, linspace(0, 1, 256)' * [1, 1, 1]);
    %% Double CLUT
    
    
    combinedClut = [dv.disp.humanCLUT;dv.disp.monkeyCLUT];
    dv.disp.overlayptr = PsychImaging('GetOverlayWindow', dv.disp.ptr);
    Screen('LoadNormalizedGammaTable', dv.disp.ptr, combinedClut, 2);
else
    dv = pdsDatapixxInit(dv);
end


%% Make procedural textures
winWidth = RectWidth(dv.disp.winRect);
winHeight = RectHeight(dv.disp.winRect);

% PLDAPS Check will run ProceduralGarboirium in the background
ngabors = 200;
support = 32; % pixels
th = 2*support+1; tw = th;
phase = 0; % Phase of underlying sine grating in degrees:
sc = 10.0; % Spatial constant of the exponential "hull"
freq = .05; % Frequency of sine grating:
contrast = .2; % Contrast of grating:
aspectratio = 0.0; % Aspect ratio width vs. height:
% concatinate a parameter matrix
mypars = repmat([phase+180, freq, sc, contrast, aspectratio, 0, 0, 0]', 1, ngabors);
% make procedural texture
if skipMakeGaborTexture
    gabortex = CreateProceduralGabor(dv.disp.ptr, tw, th, 1, [-1 -1 -1 0],1,.5);
    % draw texture once to make sure the gfx-hardware is ready
else
    dv.pa.gabSize = 5;
    dv.pa.gabSf = 2;
    dv.pa.gabContrast = .25;
    dv.pa.ngabors = ngabors;
    
    st = makeGaborTexture(dv);
    
    gabortex = st.gabTex;
end

%%


Screen('DrawTexture', dv.disp.ptr, gabortex, [], [], [], [], [], [], [], kPsychDontDoRotation, [phase, freq, sc, contrast, aspectratio, 0, 0, 0]);

texrect = Screen('Rect', gabortex);
inrect = repmat(texrect', 1, ngabors);

dstRects = zeros(4, ngabors);
for i=1:ngabors
    scale(i) = 1*(0.1 + 0.9 * randn);
    dstRects(:, i) = CenterRectOnPoint(texrect * scale(i), rand * winWidth, rand * winHeight)';
end
% Preallocate array with rotation angles:
rotAngles = rand(1, ngabors) * 360;


% Initially sync us to VBL at start of animation loop.
vbl = Screen('Flip', dv.disp.ptr);
tstart = vbl;
count = 0;

%% Kick Off Main Loop
quit = 0;
kb = pdsKeyboardSetup;
ListenChar(2)
while ~KbCheck()
    % Draw some text onto overlay window
    % Screen('DrawTexture', win, plaidTexture, [], [], [], 0);
    Screen('FillRect', dv.disp.overlayptr, 0);
    
    Screen('DrawTextures', dv.disp.ptr, gabortex, [], dstRects, rotAngles, [], [], [], [], kPsychDontDoRotation, mypars);
    
    Screen('TextSize', dv.disp.overlayptr, 36);
    Screen('Preference', 'TextAntiAliasing', 0);    % Overlay looks best w/o antialiasing
    DrawFormattedText(dv.disp.overlayptr, 'DATAPixx 16-bit monochrome demo\nwith independent left/right overlay CLUTs.\nHit any key to exit.', 'center', 'center', 128);
    
    Screen('DrawingFinished', dv.disp.ptr);
    
    % Compute updated positions and orientations for next frame. This code
    % is vectorized, but could be probably optimized even more. Indeed,
    % these few lines of Matlab code are the main speed-bottleneck for this
    % demos animation loop on modern graphics hardware, not the actual drawing
    % of the stimulus. The demo as written here is CPU bound - limited in
    % speed by the speed of your main processor.
    
    % Compute new random orientation for each patch in next frame:
    rotAngles = rotAngles + 1 * randn(1, ngabors);
    
    % Increment phase-shift of each gabor by 10 deg. per redraw:
    mypars(1,:) = mypars(1,:) + 50;
    
    % "Pulse" the aspect-ratio of each gabor with a sine-wave timecourse:
    mypars(5,:) = 1.0 + 0.25 * sin(count*0.1);
    
    % Compute centers of all patches, then shift them in new direction of
    % motion 'rotAngles', use the mod() operator to make sure they don't
    % leave the window display area. Its important to use RectCenterd and
    % CenterRectOnPointd instead of RectCenter and CenterRectOnPoint,
    % because the latter ones would round all results to integral pixel
    % locations, which would make for an odd and jerky movement. It is
    % also important to feed all matrices and vectors in proper format, as
    % these routines are internally vectorized for higher speed.
    [x y] = RectCenterd(dstRects);
    x = mod(x + 0.33 * cos(rotAngles/360*2*pi), winWidth);
    y = mod(y - 0.33 * sin(rotAngles/360*2*pi), winHeight);
    
    % Recompute dstRects destination rectangles for each patch, given the
    % 'per gabor' scale and new center location (x,y):
    dstRects = CenterRectOnPointd(inrect .* repmat(scale,4,1), x, y);
    
    Screen('Flip', dv.disp.ptr);
    
    count = count + 1;
    
end

RestoreCluts;       % Restore any system gamma tables we modified
Screen('CloseAll');
ListenChar(0)
return;