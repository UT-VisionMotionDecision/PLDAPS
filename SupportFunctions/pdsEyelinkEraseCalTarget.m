function pdsEyelinkEraseCalTarget(dv, x,y)

% erase calibration target
%
% USAGE: erasecaltarget(el, rect)
%
%		el: eyelink default values
%		rect: rect that will be filled with background colour 
if dv.disp.useOverlay
    tempcolor = dv.disp.clut.bg; 
    Screen('Drawdots',dv.disp.overlayptr,[x; y],dv.pa.fixdotW,tempcolor,[],2)
else
    tempcolor = dv.disp.bgColor';
    Screen('Drawdots',dv.disp.ptr,[x; y],dv.pa.fixdotW,tempcolor,[],2)
end

Screen( 'Flip',  dv.disp.ptr);