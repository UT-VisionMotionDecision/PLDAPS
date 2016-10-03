function p = defaultColors(p)
% p = defaultColors(p)
% Setup default color lookup tables for huklab experiments. You can modify
% these later as long as it's done before pdsDatapixxInit

% 12/13/2013 jly    Wrote it


%%% CLUT colors %%%
% note: CLUT indexing and MATLAB indexing are zero and 1-based, respectively
p.defaultParameters.display.humanCLUT = [0, 0, 0;  % IGNORE THIS LINE
    p.defaultParameters.display.bgColor; % bg           1
    0.8, 0, 0.5;  % cursor          2
    0, 1, 0;  % target color        3
    1, 0, 0;  % null target color   4
    1, 1, 1;  % window color        5
    1, 0, 0;  % fixation color      6
    1, 1, 1;  % white (dots)        7
    0, 1, 1;  % eye (turqoise)      8
    0, 0, 0;  % black (dots)        9
    0,0,1;  % blue                  10
    1,0,0; % red/green              11
    0,1,0;  % green/bg               12
    1,0,0;  % red/bg                 13
    0,0,0;  % black/bg               14
    zeros(241,3)];


p.defaultParameters.display.monkeyCLUT = [0,0,0; % IGNORE THIS LINE (CLUT is 0 based)
    p.defaultParameters.display.bgColor;     % bg (gray)          1
    p.defaultParameters.display.bgColor;     % cursor (bg)        2
    1, 0, 0;             % target color       3
    1, 0, 0;             % null target color  4
    p.defaultParameters.display.bgColor;     % window color       5
    1, 0, 0;             % fixation color     6
    1, 1, 1;             % white (dots)       7
    p.defaultParameters.display.bgColor;     % eyepos (bg)        8
    0,0,0                % black (dots)       9
    0,0,1;               % blue               10
    0,1,0; % red/green              11
    p.defaultParameters.display.bgColor;  % green/bg               12
    p.defaultParameters.display.bgColor;  % red/bg                 13
    p.defaultParameters.display.bgColor;  % black/bg               14
    zeros(241,3)];

%%% keeping track of which color is which
if p.defaultParameters.display.useOverlay %TODO make this separate from useDatapixx %(p.defaultParameters.datapixx.use && p.defaultParameters.display.useOverlay)
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
elseif p.defaultParameters.display.useOverlay %TODO add switch so choose between monkey and human clut
   p.defaultParameters.display.clut.bg         = p.defaultParameters.display.humanCLUT(1+1,:)';
   p.defaultParameters.display.clut.cursor     = p.defaultParameters.display.humanCLUT(2+1,:)';
   p.defaultParameters.display.clut.targetgood = p.defaultParameters.display.humanCLUT(3+1,:)';
   p.defaultParameters.display.clut.targetnull = p.defaultParameters.display.humanCLUT(4+1,:)';
   p.defaultParameters.display.clut.window     = p.defaultParameters.display.humanCLUT(5+1,:)';
   p.defaultParameters.display.clut.fixation   = p.defaultParameters.display.humanCLUT(6+1,:)';
   p.defaultParameters.display.clut.white      = p.defaultParameters.display.humanCLUT(7+1,:)';
   p.defaultParameters.display.clut.eyepos     = p.defaultParameters.display.humanCLUT(8+1,:)';
   p.defaultParameters.display.clut.black      = p.defaultParameters.display.humanCLUT(9+1,:)';
   p.defaultParameters.display.clut.blue       = p.defaultParameters.display.humanCLUT(10+1,:)';
   p.defaultParameters.display.clut.red        = p.defaultParameters.display.humanCLUT(4+1,:)';
   p.defaultParameters.display.clut.greenbg    = p.defaultParameters.display.humanCLUT(12+1,:)';
   p.defaultParameters.display.clut.redbg      = p.defaultParameters.display.humanCLUT(13+1,:)';
   p.defaultParameters.display.clut.blackbg    = p.defaultParameters.display.humanCLUT(14+1,:)';
else p.defaultParameters.display.useOverlay %TODO add switch so choose between monkey and human clut
   p.defaultParameters.display.clut.bg         = p.defaultParameters.display.monkeyCLUT(1+1,:)';
   p.defaultParameters.display.clut.cursor     = p.defaultParameters.display.monkeyCLUT(2+1,:)';
   p.defaultParameters.display.clut.targetgood = p.defaultParameters.display.monkeyCLUT(3+1,:)';
   p.defaultParameters.display.clut.targetnull = p.defaultParameters.display.monkeyCLUT(4+1,:)';
   p.defaultParameters.display.clut.window     = p.defaultParameters.display.monkeyCLUT(5+1,:)';
   p.defaultParameters.display.clut.fixation   = p.defaultParameters.display.monkeyCLUT(6+1,:)';
   p.defaultParameters.display.clut.white      = p.defaultParameters.display.monkeyCLUT(7+1,:)';
   p.defaultParameters.display.clut.eyepos     = p.defaultParameters.display.monkeyCLUT(8+1,:)';
   p.defaultParameters.display.clut.black      = p.defaultParameters.display.monkeyCLUT(9+1,:)';
   p.defaultParameters.display.clut.blue       = p.defaultParameters.display.monkeyCLUT(10+1,:)';
   p.defaultParameters.display.clut.red        = p.defaultParameters.display.monkeyCLUT(4+1,:)';
   p.defaultParameters.display.clut.greenbg    = p.defaultParameters.display.monkeyCLUT(12+1,:)';
   p.defaultParameters.display.clut.redbg      = p.defaultParameters.display.monkeyCLUT(13+1,:)';
   p.defaultParameters.display.clut.blackbg    = p.defaultParameters.display.monkeyCLUT(14+1,:)';
end