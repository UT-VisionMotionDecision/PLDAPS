function p=minimal_setup(p)

%these are more colors than needed, so it could in theory be reduced more
defaultColors(p);

defaultBitNames(p);

% dot sizes for drawing
p.defaultParameters.stimulus.eyeW      = 8;    % eye indicator width in pixels
p.defaultParameters.stimulus.cursorW   = 8;   % cursor width in pixels

    