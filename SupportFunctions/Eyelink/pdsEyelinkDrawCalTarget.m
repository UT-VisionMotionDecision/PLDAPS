function pdsEyelinkDrawCalTarget(dv, x, y)
% pdsEyelinkDrawCalTarget(dv, x, y)
% draw simple calibration target (PLDAPS version)
% subroutine called by pdsEyelinkCalibrate modified from PTB version
%
% USAGE: pdsEyelinkDrawCalTarget(el, x, y)
%
%		dv: display variables
%		x,y: position at which it should be drawn

% simple, standard eyelink version
%   22-06-06    fwc OSX-ed
%   12-12-13    jly Takes in dv struct and draws dots instead of ovals

if dv.disp.useOverlay
    tempcolor = dv.disp.clut.targetgood; 
    Screen('FillRect', dv.disp.overlayptr, 0); 
    Screen('Drawdots',dv.disp.overlayptr,[x; y],dv.pa.fixdotW,tempcolor,[],2)
else
    tempcolor = [1 0 0]';
    Screen('Drawdots',dv.disp.ptr,[x; y],dv.pa.fixdotW,tempcolor,[],2)
end

Screen( 'Flip',  dv.disp.ptr);
