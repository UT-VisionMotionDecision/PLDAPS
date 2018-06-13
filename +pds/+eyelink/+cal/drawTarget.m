function drawTarget(p, xy, bufferIdx)
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

if any(size(xy)==1)
    % column vector
    xy = xy(:);
elseif size(xy,1)>2
    warning('\t%s\n\ttarget positions must be 2-by-n [xy] coords. Nothing drawn!\n', mfilename);
    return
end

if nargin<3
    % no buffer index specified; render to all present
    bufferIdx = p.trial.display.bufferIdx;
end

% Dot size (No more digging around for it...must be in core .eyelink module)
fixdotW = p.trial.eyelink.fixdotW;

if isfield(p.trial.display.clut,'white')
    dotcolor = WhiteIndex(p.trial.display.ptr);     % p.trial.display.monkeyCLUT(p.trial.display.clut.fixation(1)+1,:);
else
    dotcolor = [1 1 1]';
end

% % Use of different rendering colors for subject & experimenter displays is not supported in glDraw
% % ...would like this to come back, but gets hairy with stereo drawing and RB3D implementation of overlay (vpixx never finished proper firmware implementation)
% if p.trial.display.useOverlay
%     Screen('FillRect', p.trial.display.overlayptr, 0); 
%     Screen('Drawdots',p.trial.display.overlayptr,[x; y], fixdotW, dotcolor,[],2);
% else
for i = bufferIdx
    Screen('SelectStereoDrawBuffer', p.trial.display.ptr, i);
    Screen('Drawdots',p.trial.display.ptr, xy, fixdotW, dotcolor,[],2);
end
% end

Screen( 'Flip',  p.trial.display.ptr, 0);
