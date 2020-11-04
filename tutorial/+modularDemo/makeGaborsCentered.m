function [p] = makeGaborsCentered(p, sn, verbo)
% function [p] = visBasics.makeGabors(p, sn)
% 
% [p] is pldaps object that must have p.trial.display fields present
%    --ideally, this should be exeduted by a PLDAPS module during experimentPostOpenScreen state
% 
% [sn] is string name of the module these gabors will be placed in
% 
% 
% TBC 01-29-09  Made it
% TBC 03-04-09  Combined all fixation objects into one texture
% 2017-10-11  TBC  Rough update for PLDAPS modular use (call to setup during "experimentPostOpenScreen")
% 2018-06-28  TBC  Tuned up reeeal nice like.
% 2020-10-16  TBC  Gabor positioning update!
%                  - NEW [.centerOnScreen] flag to use screen center as origin,
%                  -- destRect texture coords now consistent with Screen('DrawDots'..)
%                  -- if absent or ==0, will behave exactly as previously (origin upper-left & reversed Y-axis)
% 

%% Input checking
if nargin<3
    % render sample gabor onscreen
    verbo = 0;
end

% pldaps module string name
if nargin<2 || isempty(sn)
    sn = 'stimulus';
end

if ~isField(p.trial, sn)
    % This should never be the case. You should setup basic modularPldaps fields by now
    fprintf(2, '\n\tERROR:\tBasic initialization of module .%s. must be done by now.\n', sn);
    keyboard
end


%% Default params    
defs = { ...
    'gabSd',    1.5; ...
    'gabSf',    2; ...
    'gabContrast', 1; ...
    'ngabors',  1; ...
    'pos',      [0; 0]; ...
    'dir',      0; ...
    'centerOnScreen', 0};

for i = 1:size(defs,1)
    if ~isfield(p.trial.(sn), defs{i,1})
        p.trial.(sn).(defs{i,1}) = defs{i,2};
    end
end


% Convert between various gabor size input parameters
% *** In most experimental cases, FWHM is the ideal input parameter for stimulus size ***
%
if isfield(p.trial.(sn),'gabSize') % older code used this as size of 8-bit support structure, which led to ambiguity/confusion
    % Convert to corresponding standard deviation of gaussian hull
    p.trial.(sn).gabSd = p.trial.(sn).gabSize / 7;
end
if isfield(p.trial.(sn),'gabFwhm')
    % FWHM is the most human-readable size param, but corresponding gaussian sd param must be passed into the shader
    % full-width half-max (approx. 2.355*std of exponential hull)
    p.trial.(sn).gabSd = p.trial.(sn).gabFwhm / sqrt(8*log(2));
else
    % compute FWHM if input param was something different 
    p.trial.(sn).gabFwhm = p.trial.(sn).gabSd * sqrt(8*log(2));
end

% Compute dependent params
p.trial.(sn).gabPixCycle = p.trial.(sn).gabSf / p.trial.display.ppd;   % pix/deg * deg/cycle = pix/cycle
p.trial.(sn).gabPixels = 8 * p.trial.(sn).gabSd .* p.trial.display.ppd;   % size of support rect in pixels. "8" provides 4*sd of gaussian hull in either direction (>enough for 8-bit resolution)
texSz = ceil(p.trial.(sn).gabPixels); % gabor support width [int]
%height = width;  % circular gabors only (...nonsymmetric gabs are possible, but require more complex/slower shader)


%% Create gabor texture
[gabTex, texRect, gabShader] = CreateLuminanceGabor(p.trial.display.ptr, texSz, p.trial.(sn).centerOnScreen);
% Sub-function is based on CreateProceduralGabor.m; tuned for purpose & with parameters so that contrast values
% correspond to expected Michelson contrast onscreen.
% [gabTexture, texRect] = CreateLuminanceGabor(windowPtr, texSz, screenCtr)
%   --Technically this subfunction only creates the openGL texture substrate necessary for procedural rendering
%   & links the screen pointer & center parameters into the shader. The rest depends on the individual gabor &
%   destination rect parameters (p.trial.(sn).Gpars & destRect) that you pass into Screen('DrawTextures'...)

p.trial.(sn).gabTex     = gabTex;
p.trial.(sn).texRect    = texRect;
p.trial.(sn).texSz      = texSz; % always square
p.trial.(sn).gabShader  = gabShader; % need shader handle to update uniforms otf
% p.trial.(sn).texW       = width;
% p.trial.(sn).texH       = height;

% Retrieve low-level OpenGL parameters (jic)
[gid, gtarg, gu, gv] = Screen('GetOpenGLTexture', p.trial.display.ptr, p.trial.(sn).gabTex);
p.trial.(sn).gl = struct('id',gid, 'targ',gtarg, 'u',gu, 'v',gv);


%% Individual gabor parameter matrix
% [phase] degrees 0:360
% [sc] standard deviation of gaussian hull **
% [freq] spatial frequency of sin wave **
% [con] Michelson contrast
%   ** sc & con must be pixel-based units for the shader, so actual values may not be terribly 'human readable' 
phase = 0;
sc = p.trial.(sn).gabSd * p.trial.display.ppd; % std of gaussian hull in pixels!
freq = p.trial.(sn).gabPixCycle;
con = p.trial.(sn).gabContrast;

% Create default 4-by-ngabor-by-"nEyes" parameter matrix
p.trial.(sn).Gpars = repmat( [phase, freq, sc, con]', [1, p.trial.(sn).ngabors, numel(p.trial.display.bufferIdx)]);


%% Show example stimulus?
if verbo
    % AhHa! destination rect is just [x, y, 1, 1] position!!    dstRect = [0 0 1 1];% 
    dstRect = CenterRectOnPoint(p.trial.(sn).texRect, p.trial.display.ctr(1), p.trial.display.ctr(2));
    % Render a single gabor via DrawTextures:
    %   Screen('DrawTextures', winPtr, gabTex, [], [destRect], [angle], [], [], [modulateColor], [], kPsychDontDoRotation, Gpars);
    Screen('DrawTextures', p.trial.display.ptr, p.trial.(sn).gabTex, [], dstRect, [1], [], [], [], [], kPsychDontDoRotation, p.trial.(sn).Gpars(:,1,1));
fprintf('\n\n\tp.trial.%s.Gpars = [phase, freq, sigma, contrast] by .ngabors\n', sn)
end
   
%p.trial.(sn)


end

% % % % % % % % % % 
%% Sub Functions
% % % % % % % % % %

function [gabTexture, texRect, gaborShader] = CreateLuminanceGabor(windowPtr, texSz, centerOnScreen)

% need low-level GL struct
global GL

% Flag to shift texture rendering origin to center of screen & invert Y-axis
% - Match behavior of Screen(DrawDots,...) using [center] == .display.ctr
% - +Y is above Horiz merid, +X is right of center
if nargin<3 || isempty(centerOnScreen)
    % Behave like normal DrawTextures call
    % - destRect positioned relative to upper left corner of screen
    centerOnScreen = 0;
end
    
% Load simplified luminance gabor shader (found in: .../PLDAPS/SupportFunctions/Utils/)
shaderSrc = 'gaborShaderCentered';  % 'gaborShader';    %
shaderPath = fullfile(fileparts(which([shaderSrc,'.vert.txt'])), shaderSrc);
gaborShader = LoadGLSLProgramFromFiles( shaderPath, 0 );    % this will load both .frag & .vert shaders by default

% Setup shader:
glUseProgram(gaborShader);

% Set the 'Center' parameter to the center position of the gabor texture rect [tw/2, th/2]:
glUniform2f(glGetUniformLocation(gaborShader, 'Center'), texSz/2, texSz/2); % 0,0);%

% Automatically offset position by screen center!
glUniform1i(glGetUniformLocation(gaborShader, 'centerOnScreen'), int16(centerOnScreen));

% Setup done:
glUseProgram(0);

% Create a purely virtual procedural texture of size width x height virtual pixels.
% Attach the GaborShader to it to define its appearance:
gabTexture = Screen('SetOpenGLTexture', windowPtr, [], 0, GL.TEXTURE_RECTANGLE_EXT, texSz, texSz, 1, gaborShader);

% Query and return its bounding rectangle:
texRect = Screen('Rect', gabTexture);

% Done!
end