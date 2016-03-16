function pdsEyelinkEraseCalTarget(p, x,y)

% erase calibration target
%
% USAGE: erasecaltarget(el, rect)
%
%		el: eyelink default values
%		rect: rect that will be filled with background colour 
if p.trial.display.useOverlay
    tempcolor = p.trial.display.clut.bg;
    Screen('Drawdots',p.trial.display.overlayptr,[x; y],p.trial.stimulus.fixdotW,tempcolor,[],2)
else
    tempcolor = p.trial.display.bgColor';
    Screen('Drawdots',p.trial.display.ptr,[x; y],p.trial.stimulus.fixdotW,tempcolor,[],2)
end

Screen( 'Flip',  p.trial.display.ptr);