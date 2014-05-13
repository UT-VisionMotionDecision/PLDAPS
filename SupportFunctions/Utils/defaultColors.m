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
dv.defaultParameters.display.clut.bg         = 1;
dv.defaultParameters.display.clut.cursor     = 2;
dv.defaultParameters.display.clut.targetgood = 3;
dv.defaultParameters.display.clut.targetnull = 4;
dv.defaultParameters.display.clut.window     = 5;
dv.defaultParameters.display.clut.fixation   = 6;
dv.defaultParameters.display.clut.white      = 7;
dv.defaultParameters.display.clut.eyepos     = 8;
dv.defaultParameters.display.clut.black      = 9;
dv.defaultParameters.display.clut.blue       = 10;
dv.defaultParameters.display.clut.red        = 4;