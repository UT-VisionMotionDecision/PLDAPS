function pdsEyelinkEraseCalTarget(dv, x,y)
% pdsEyelinkEraseCalTarget(dv, x,y)
% erase calibration target subroutine called by pdsEyelinkCalibrate
%
% USAGE: pdsEyelinkEraseCalTarget(dv, x,y)
%
%		dv:  pldaps values
%		x,y: position of target
if dv.disp.useOverlay
    tempcolor = dv.disp.clut.bg; 
    Screen('Drawdots',dv.disp.overlayptr,[x; y],dv.pa.fixdotW,tempcolor,[],2)
else
    tempcolor = dv.disp.bgColor';
    Screen('Drawdots',dv.disp.ptr,[x; y],dv.pa.fixdotW,tempcolor,[],2)
end

Screen( 'Flip',  dv.disp.ptr);