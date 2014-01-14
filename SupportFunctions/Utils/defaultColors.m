function dv = defaultColors(dv)
% dv = defaultColors(dv)
% Setup default color lookup tables for huklab experiments. You can modify
% these later as long as it's done before pdsDatapixxInit

% 12/13/2013 jly    Wrote it


%%% CLUT colors %%%
% note: CLUT indexing and MATLAB indexing are zero and 1-based, respectively
dv.disp.humanCLUT = [0, 0, 0;  % IGNORE THIS LINE
    dv.disp.bgColor; % bg           1
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


dv.disp.monkeyCLUT = [0,0,0; % IGNORE THIS LINE (CLUT is 0 based)
    dv.disp.bgColor;     % bg (gray)          1
    dv.disp.bgColor;     % cursor (bg)        2
    1, 0, 0;             % target color       3
    1, 0, 0;             % null target color  4
    dv.disp.bgColor;     % window color       5
    1, 0, 0;             % fixation color     6
    1, 1, 1;             % white (dots)       7
    dv.disp.bgColor;     % eyepos (bg)        8
    0,0,0                % black (dots)       9
    0,0,1;               % blue               10
    zeros(245,3)];

%%% keeping track of which color is which
dv.disp.clut.bg         = 1;
dv.disp.clut.cursor     = 2;
dv.disp.clut.targetgood = 3;
dv.disp.clut.targetnull = 4;
dv.disp.clut.window     = 5;
dv.disp.clut.fixation   = 6;
dv.disp.clut.white      = 7;
dv.disp.clut.eyepos     = 8;
dv.disp.clut.black      = 9;
dv.disp.clut.blue       = 10;
dv.disp.clut.red        = 4;