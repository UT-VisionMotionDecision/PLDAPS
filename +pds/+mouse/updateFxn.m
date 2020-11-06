function pos = updateFxn(p)
% pos = pds.mouse.updateFxn(p)
% 
% 
% %!%!%!% WARNING %!%!%!%
%
%   This method DOES NOT RECORD the timecourse of [sample] data
%   - This fxn is about fast retrieval of current data from mouse
%   - Leaving continuous data recording functions to code specific to
%     tracking source device; e.g. standard mouse polling done in
%     pldapsDefaultTrialFunction.
%
% %!%!%!% WARNING %!%!%!%
% 
% 
% Get current mouse position. Updated for use with pds.tracking methods.
% -- Returns only the current position of mouse; does nothing to [p] structure
% -- Does *not* update p.trial.eyeX, .eyeY (...that task resides in pds.tracking.frameUpdate.m)
%
% INPUTS:
%   [p]      Active PLDAPS structure/object
% 
% OUTPUT:
%   [pos]    XY position data, as 2-by-1 
%            -- format is clunky elsewhere, but allows blind indexing of "pos(1)" & "pos(2)"
%               to return an X & Y pair, regardless of whether tracking is mono or bino.
%               (scrappy, but occasionally useful...TBD if its worth it)
% 
% 2019-12-10  TBC  wrote it.

% Evolved from pds.eyelink.getQueue.m


% Poll mouse
[cursorX, cursorY] = GetMouse(p.trial.mouse.windowPtr);

% return position as 2-by-n
pos = [cursorX, cursorY]';



end %main function