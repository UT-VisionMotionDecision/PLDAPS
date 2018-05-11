function p = defaultColors(p, activeClut)
% p = defaultColors(p, [activeClut])
% Setup default color lookup tables for huklab experiments. You can modify
% these later as long as it's done BEFORE p.run (technically before pds.datapixx.init)
% 
% [p]           pldaps object structure that should have p.trial.display
% [activeClut]  optional string to select visible clut when not using Overlay
%               'monkeyCLUT'(default) or 'humanCLUT'
%
% 12/13/2013 jly    Wrote it
% 2018-03-28  TBC   Polished, binocular compat.

bgColor = p.defaultParameters.display.bgColor;
clutDepth = 2^8;

if nargin<2
    activeClut = [];
end

%% CLUT colors %%%
% note: CLUT indexing is 0-based, MATLAB indexing is 1-based
p.defaultParameters.display.humanCLUT = [0, 0, 0;  % IGNORE THIS LINE
    bgColor;    % background            1
    0.8, 0, 0.5;% cursor                2
    0, 1, 0;    % target color          3
    1, 0, 0;    % null target color     4
    1, 1, 1;    % window color          5
    1, 0, 0;    % fixation color        6
    1, 1, 1;    % white (dots)          7
    0, 1, 1;    % eyepos/eye0 (cyan)    8
    0, 0, 0;    % black (dots)          9
    0, 0, 1;    % blue                  10
    1, 0, 0;    % red/green             11
    0, 1, 0;    % green/bg              12
    1, 0, 0;    % red/bg                13
    0, 0, 0;    % black/bg              14
    0, 0.6, 1]; % eye1 (blue-green)     15
    
    % extend clut length to clutDepth (8-bit)
    p.defaultParameters.display.humanCLUT(clutDepth, 1:3) = 0;


p.defaultParameters.display.monkeyCLUT = [0,0,0; % IGNORE THIS LINE (CLUT is 0 based)
    bgColor;    % bg (grey)             1
    bgColor;    % cursor (bg)           2
    1, 0, 0;    % target color          3
    1, 0, 0;    % null target color     4
    bgColor;    % window color          5
    1, 0, 0;    % fixation color        6
    1, 1, 1;    % white (dots)          7
    bgColor;    % eyepos/eye0 (bg)      8
    0,0,0       % black (dots)          9
    0,0,1;      % blue                  10
    0,1,0;      % red/green             11
    bgColor;    % green/bg              12
    bgColor;    % red/bg                13
    bgColor;    % black/bg              14
    bgColor];   % eye1 (bg)             15

    % extend clut length to clutDepth (8-bit)
    p.defaultParameters.display.monkeyCLUT(clutDepth, 1:3) = 0;

%% Add symantic labels for clut values
if p.defaultParameters.display.useOverlay % Overlay clut must be indexed 8-bit 
    p.defaultParameters.display.clut.bg         = 1*[1 1 1]';
    p.defaultParameters.display.clut.cursor     = 2*[1 1 1]';
    p.defaultParameters.display.clut.targetgood = 3*[1 1 1]';
    p.defaultParameters.display.clut.targetnull = 4*[1 1 1]';
    p.defaultParameters.display.clut.window     = 5*[1 1 1]';
    p.defaultParameters.display.clut.fixation   = 6*[1 1 1]';
    p.defaultParameters.display.clut.white      = 7*[1 1 1]';
    p.defaultParameters.display.clut.eyepos     = 8*[1 1 1]';
    p.defaultParameters.display.clut.black      = 9*[1 1 1]';
    p.defaultParameters.display.clut.blue       = 10*[1 1 1]';
    p.defaultParameters.display.clut.red        = 4*[1 1 1]';
    p.defaultParameters.display.clut.greenbg    = 12*[1 1 1]';
    p.defaultParameters.display.clut.redbg      = 13*[1 1 1]';
    p.defaultParameters.display.clut.blackbg    = 14*[1 1 1]';
    p.defaultParameters.display.clut.eye0       = 8*[1 1 1]';
    p.defaultParameters.display.clut.eye1       = 15*[1 1 1]';
    
else
    if isempty(activeClut)
        activeClut = 'monkeyCLUT';
    end
    
    p.defaultParameters.display.clut.bg         = p.defaultParameters.display.(activeClut)(1+1,:)';
    p.defaultParameters.display.clut.cursor     = p.defaultParameters.display.(activeClut)(2+1,:)';
    p.defaultParameters.display.clut.targetgood = p.defaultParameters.display.(activeClut)(3+1,:)';
    p.defaultParameters.display.clut.targetnull = p.defaultParameters.display.(activeClut)(4+1,:)';
    p.defaultParameters.display.clut.window     = p.defaultParameters.display.(activeClut)(5+1,:)';
    p.defaultParameters.display.clut.fixation   = p.defaultParameters.display.(activeClut)(6+1,:)';
    p.defaultParameters.display.clut.white      = p.defaultParameters.display.(activeClut)(7+1,:)';
    p.defaultParameters.display.clut.eyepos     = p.defaultParameters.display.(activeClut)(8+1,:)';
    p.defaultParameters.display.clut.black      = p.defaultParameters.display.(activeClut)(9+1,:)';
    p.defaultParameters.display.clut.blue       = p.defaultParameters.display.(activeClut)(10+1,:)';
    p.defaultParameters.display.clut.red        = p.defaultParameters.display.(activeClut)(4+1,:)';
    p.defaultParameters.display.clut.greenbg    = p.defaultParameters.display.(activeClut)(12+1,:)';
    p.defaultParameters.display.clut.redbg      = p.defaultParameters.display.(activeClut)(13+1,:)';
    p.defaultParameters.display.clut.blackbg    = p.defaultParameters.display.(activeClut)(14+1,:)';
    p.defaultParameters.display.clut.eye0       = p.defaultParameters.display.(activeClut)(8+1,:)';
    p.defaultParameters.display.clut.eye1       = p.defaultParameters.display.(activeClut)(15+1,:)';
    
end