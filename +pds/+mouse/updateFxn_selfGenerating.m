function pos = updateFxn_selfGenerating(ptr)
% pos = pds.mouse.updateFxn(p)
% 
% TEST:  Don't pass in full pldaps structure, only need pointer from p.trial.mouse.windowPtr
%   -- Setup function handle as:
%       fxn = @pds.mouse.updateFxn(p.trial.mouse.windowPtr);
% 
% ~~~~~~~~~~
% YES!  (And shti)
%   Discovered major problem with function handles inside the p.trial struct (i.e. params class struct)
%   is the fact that most such cases involve functions that take the PLDAPS object as input  (e.g.  out = fxn(p, stuff);)
%   Result is that the function handle workspace includes its own [giant] copy of the pldaps object, and/or
%   all variable access within it must also call all the klunky params struct heirarchy referencing code.
% 
%   Function handles that take simple/numeric inputs are just fine as function handles inside of p.trial
%   
%   Method of self generating function handle with inputs employed in this code works, but is another layer of
%   krufty hacky implementation, and not a reasonable to ask for future users to implement on their own.
% 
%   MUST GET RID OF PARAMS CLASS!!!!
% 
%   TBC 2020-01-09
% ~~~~~~~~~~
% 
% Get current mouse position. Updated version of pds.eyelink.getQueue.m for use with
% pds.tracking methods.
% -- Returns only the current position of all eyes tracked; does nothing to [p] structure
% -- Does *not* update p.trial.eyeX as old getQueue function did (...task now resides in pds.tracking.frameUpdate.m)
%
% INPUTS:
%   [p]      Active PLDAPS structure/object
%   [useRaw] Logical flag (default==true). if useRaw==false, will index to calibrated 'gaze' data
% 
% OUTPUT:
%   [pos]    XY position data, as 2-by-nEyes:   eyeL = pos(:,1); eyeR = pos(:,2);
%            -- format is clunky elsewhere, but allows blind indexing of "pos(1)" & "pos(2)"
%               to return an X & Y pair, regardless of whether tracking is mono or bino.
%               (scrappy, but occasionally useful...TBD if its worth it)
% 
%
% 2013-12-xx  jly  wrote it
% 2014-xx-xx  jk   adapted it for version 4.1
% 2019-12-10  TBC  [re]wrote it.

% Evolved from pds.eyelink.getQueue.m

% Initialize
if nargin<1
    % reach up to caller and retrieve necessary inputs from PLDAPS struct
        fxnInputs = evalin('caller', 'p.trial.mouse.windowPtr');
    if isempty(fxnInputs)
        fxnInputs = {-1};
    else
        fxnInputs = {fxnInputs};
    end
    % return a handle to this function with those inputs
    pos = eval(sprintf('@()pds.mouse.updateFxn(%d)', fxnInputs{:} ));
    
else
    % edge case
    ptr(ptr<0) = [];

    % Poll mouse
    [cursorX, cursorY] = GetMouse( ptr );
    pos = [cursorX, cursorY]';
end


end %main function