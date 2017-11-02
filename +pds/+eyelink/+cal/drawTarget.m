function drawTarget(p, x, y)
% function drawTarget(p, x, y)
% draw simple calibration target (PLDAPS version)
%
% USAGE: pds.eyelink.cal.drawTarget(p, x, y)
%   (previously pdsEyelinkDrawCalTarget.m)
%		p: Pldaps structure/object
%		x,y: position at which it should be drawn
% 
% simple, standard eyelink version
%   22-06-06    fwc OSX-ed
%   12-12-13    jly Takes in p struct and draws dots instead of ovals
% 2017-11-02  TBC  Compiled into pds.eyelink.cal package, standardized
%                  Remove hard dependency on p.trial.stimulus
% 

if isfield(p.trial.eyelink, 'fixdotW')
    fixdotW = p.trial.eyelink.fixdotW;
elseif isfield(p.trial, 'stimulus') && isfield(p.trial.stimulus, 'fixdotW')
    fixdotW = p.trial.stimulus.fixdotW;
else
    fixdotW = 15;
end

if p.trial.display.useOverlay
    tempcolor = p.trial.display.clut.targetgood; 
    Screen('FillRect', p.trial.display.overlayptr, 0); 
    Screen('Drawdots',p.trial.display.overlayptr,[x; y], fixdotW, tempcolor,[],2)
else
    tempcolor = [1 0 0]';
    Screen('Drawdots',p.trial.display.ptr,[x; y], fixdotW, tempcolor,[],2)
end

Screen( 'Flip',  p.trial.display.ptr);
