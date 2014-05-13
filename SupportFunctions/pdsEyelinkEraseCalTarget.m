function pdsEyelinkEraseCalTarget(dv, x,y)

% erase calibration target
%
% USAGE: erasecaltarget(el, rect)
%
%		el: eyelink default values
%		rect: rect that will be filled with background colour 
if dv.trial.display.useOverlay
    tempcolor = dv.trial.display.clut.bg; 
    Screen('Drawdots',dv.trial.display.overlayptr,[x; y],dv.trial.stimulus.fixdotW,tempcolor,[],2)
else
    tempcolor = dv.trial.display.bgColor';
    Screen('Drawdots',dv.trial.display.ptr,[x; y],dv.trial.stimulus.fixdotW,tempcolor,[],2)
end

Screen( 'Flip',  dv.trial.display.ptr);