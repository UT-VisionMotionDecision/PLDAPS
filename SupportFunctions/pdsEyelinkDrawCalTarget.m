function pdsEyelinkDrawCalTarget(dv, x, y)
% draw simple calibration target (PLDAPS version)
%
% USAGE: EyelinkDrawCalTarget(el, x, y)
%
%		dv: display variables
%		x,y: position at which it should be drawn

% simple, standard eyelink version
%   22-06-06    fwc OSX-ed
%   12-12-13    jly Takes in dv struct and draws dots instead of ovals

if dv.trial.display.useOverlay
    tempcolor = dv.trial.display.clut.targetgood; 
    Screen('FillRect', dv.trial.display.overlayptr, 0); 
    Screen('Drawdots',dv.trial.display.overlayptr,[x; y],dv.trial.stimulus.fixdotW,tempcolor,[],2)
else
    tempcolor = [1 0 0]';
    Screen('Drawdots',dv.trial.display.ptr,[x; y],dv.trial.stimulus.fixdotW,tempcolor,[],2)
end

Screen( 'Flip',  dv.trial.display.ptr);
