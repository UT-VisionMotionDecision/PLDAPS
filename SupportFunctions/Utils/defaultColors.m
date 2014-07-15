function dv = defaultColors(dv)
% dv = defaultColors(dv)
% Setup default color lookup tables for huklab experiments. You can modify
% these later as long as it's done before pdsDatapixxInit

% 12/13/2013 jly    Wrote it


%%% CLUT colors %%%
% note: CLUT indexing and MATLAB indexing are zero and 1-based, respectively
dv.defaultParameters.display.humanCLUT = [0, 0, 0;  % IGNORE THIS LINE
    dv.defaultParameters.display.bgColor; % bg           1
    0.8, 0, 0.5;  % cursor          2
    0, 1, 0;  % target color        3
    1, 0, 0;  % null target color   4
    1, 1, 1;  % window color        5
    1, 0, 0;  % fixation color      6
    1, 1, 1;  % white (dots)        7
    0, 1, 1;  % eye (turqoise)      8
    0, 0, 0;  % black (dots)        9
    0,0,1;  % blue                  10
    zeros(245,3)];


dv.defaultParameters.display.monkeyCLUT = [0,0,0; % IGNORE THIS LINE (CLUT is 0 based)
    dv.defaultParameters.display.bgColor;     % bg (gray)          1
    dv.defaultParameters.display.bgColor;     % cursor (bg)        2
    1, 0, 0;             % target color       3
    1, 0, 0;             % null target color  4
    dv.defaultParameters.display.bgColor;     % window color       5
    1, 0, 0;             % fixation color     6
    1, 1, 1;             % white (dots)       7
    dv.defaultParameters.display.bgColor;     % eyepos (bg)        8
    0,0,0                % black (dots)       9
    0,0,1;               % blue               10
    zeros(245,3)];

%%% keeping track of which color is which
if(dv.defaultParameters.datapixx.use && dv.defaultParameters.display.useOverlay)
    dv.defaultParameters.display.clut.bg         = 1*[1 1 1]';
    dv.defaultParameters.display.clut.cursor     = 2*[1 1 1]';
    dv.defaultParameters.display.clut.targetgood = 3*[1 1 1]';
    dv.defaultParameters.display.clut.targetnull = 4*[1 1 1]';
    dv.defaultParameters.display.clut.window     = 5*[1 1 1]';
    dv.defaultParameters.display.clut.fixation   = 6*[1 1 1]';
    dv.defaultParameters.display.clut.white      = 7*[1 1 1]';
    dv.defaultParameters.display.clut.eyepos     = 8*[1 1 1]';
    dv.defaultParameters.display.clut.black      = 9*[1 1 1]';
    dv.defaultParameters.display.clut.blue       = 10*[1 1 1]';
    dv.defaultParameters.display.clut.red        = 4*[1 1 1]';
elseif dv.defaultParameters.display.useOverlay %TODO add switch so choose between monkey and human clut
   dv.defaultParameters.display.clut.bg         = dv.defaultParameters.display.humanCLUT(1+1,:)';
   dv.defaultParameters.display.clut.cursor     = dv.defaultParameters.display.humanCLUT(2+1,:)';
   dv.defaultParameters.display.clut.targetgood = dv.defaultParameters.display.humanCLUT(3+1,:)';
   dv.defaultParameters.display.clut.targetnull = dv.defaultParameters.display.humanCLUT(4+1,:)';
   dv.defaultParameters.display.clut.window     = dv.defaultParameters.display.humanCLUT(5+1,:)';
   dv.defaultParameters.display.clut.fixation   = dv.defaultParameters.display.humanCLUT(6+1,:)';
   dv.defaultParameters.display.clut.white      = dv.defaultParameters.display.humanCLUT(7+1,:)';
   dv.defaultParameters.display.clut.eyepos     = dv.defaultParameters.display.humanCLUT(8+1,:)';
   dv.defaultParameters.display.clut.black      = dv.defaultParameters.display.humanCLUT(9+1,:)';
   dv.defaultParameters.display.clut.blue       = dv.defaultParameters.display.humanCLUT(10+1,:)';
   dv.defaultParameters.display.clut.red        = dv.defaultParameters.display.humanCLUT(4+1,:)';
else dv.defaultParameters.display.useOverlay %TODO add switch so choose between monkey and human clut
   dv.defaultParameters.display.clut.bg         = dv.defaultParameters.display.monkeyCLUT(1+1,:)';
   dv.defaultParameters.display.clut.cursor     = dv.defaultParameters.display.monkeyCLUT(2+1,:)';
   dv.defaultParameters.display.clut.targetgood = dv.defaultParameters.display.monkeyCLUT(3+1,:)';
   dv.defaultParameters.display.clut.targetnull = dv.defaultParameters.display.monkeyCLUT(4+1,:)';
   dv.defaultParameters.display.clut.window     = dv.defaultParameters.display.monkeyCLUT(5+1,:)';
   dv.defaultParameters.display.clut.fixation   = dv.defaultParameters.display.monkeyCLUT(6+1,:)';
   dv.defaultParameters.display.clut.white      = dv.defaultParameters.display.monkeyCLUT(7+1,:)';
   dv.defaultParameters.display.clut.eyepos     = dv.defaultParameters.display.monkeyCLUT(8+1,:)';
   dv.defaultParameters.display.clut.black      = dv.defaultParameters.display.monkeyCLUT(9+1,:)';
   dv.defaultParameters.display.clut.blue       = dv.defaultParameters.display.monkeyCLUT(10+1,:)';
   dv.defaultParameters.display.clut.red        = dv.defaultParameters.display.monkeyCLUT(4+1,:)';
end