function eraseTarget(p, x,y)
% function eraseTarget(p, x,y)
% erase calibration target
%
% USAGE: pds.eyelink.cal.eraseTarget(p, x,y)
%   (previously pdsEyelinkEraseCalTarget.m)
%
% [p]   Pldaps structure
% [x],[y] target location


if isfield(p.trial.eyelink, 'fixdotW')
    fixdotW = p.trial.eyelink.fixdotW;
elseif isfield(p.trial, 'stimulus') && isfield(p.trial.stimulus, 'fixdotW')
    fixdotW = p.trial.stimulus.fixdotW;
else
    fixdotW = 15;
end

if p.trial.display.useOverlay
    tempcolor = p.trial.display.clut.bg;
    Screen('Drawdots',p.trial.display.overlayptr,[x; y], fixdotW, tempcolor,[],2)
else
    tempcolor = p.trial.display.bgColor(:);
    Screen('Drawdots',p.trial.display.ptr,[x; y], fixdotW, tempcolor,[],2)
end

Screen( 'Flip',  p.trial.display.ptr);