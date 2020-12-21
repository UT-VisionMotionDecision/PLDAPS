function p = setViewdist(p, newdist, forceUpdate)
% function p = pds.display.setViewdist(p, newdist)
%
% Update any display variables that are dependent on viewing distance
% **Generally unnecessary to call this function directly**
%   Best practice to update value of [p.static.display.viewdist], 
%   then allow object 'property set' event listener to do it's thing.
% 
% With advent of pdsDisplay object class (Fall 2020), variables that
% are dependent on viewing distance can now be coded to be just that!
% The traditional [p.trial.display] still exists, its just updated on
% every trial based on the contents of the [p.static.display] object.
% 
% If .grbl module is present for automated display positioning, this
% function will initiate homing sequence & repositioning automagically!
% --------------------------
% INPUTS:
% [p]           Standard PLDAPS object
% [newdist]     Desired new viewing distance (in cm)
%               - only updates if different from previous
% [forceUpdate] Update regardless of change in viewdist.
%               - important for initialization & tracking calibration
% 
% --------------------------
% NOTE on [p.static] vs [p.trial]
% -- Things like physical distance aren't just "reset" when parameters for
%    a new trial are initialized, so it is necessary to override some aspects
%    of [p.trial]
% -- [p.static] later morphed into a more general way to maintain OOP objects
%    across trials
% 
% 2020-11-xx TBC  Wrote it.
% 

%% defaults
debug = false;

if nargin<3 || isempty(forceUpdate)
    doUpdate = 0;
else
    doUpdate = forceUpdate;
end

if exist('newdist','var') && ~isempty(newdist)
    % Quirky loop b/c this function is now called automatically by property
    % listener on [p.static.display.viewdist].
    %   -If attempting to use this function to set a viewdist, then use input
    %    to trigger the listener callback & return
    %   - ...better to just set .viewdist & trigger callback directly
    p.static.display.viewdist = newdist;
    if ~forceUpdate
        return
    end
end

% check if viewdist different from previous
if p.trial.display.viewdist ~= p.static.display.viewdist
    doUpdate = 1;
end

% DEBUG
if debug
    fprintf('\n\tppd = %3.3f\t', p.trial.display.ppd);
end

% check for physical positioning module [grbl]
% -- ugly coding due to 'params' class garbage
if (isfield(p.trial,'grbl') || (isa(p.trial,'params') && isField(p.trial,'grbl')))   &&   p.trial.grbl.use 
    sn = 'grbl';
    switch p.trial.(sn).state
        case 'Alarm'
            % initiate homing
            grbl.homeWithWarning(p, sn);
            p.trial.(sn).homingState = 1; % true homing completed
    end
    
    % get current position directly from device
    p.trial.(sn) = grbl.updatePos(p.trial.(sn));
    % Compute new grbl position in machine coordinates (cm)
    % -- p.trial.display.homeDist is the viewing distance when display is in the HOME position
    % -- ** Should be farthest point away from subject
    % Determine .grblPos by subtracting off the desired viewing distance from .homeDist:
    %    p.trial.display.grblPos = p.trial.display.homeDist - p.trial.display.viewdist;
    %      !!NOTE!!
    %      .grblPos should always be derived from .viewdist, not the other way around !!
    thisPos = p.trial.display.homeDist - p.trial.display.viewdist;
    if p.trial.(sn).pos(1) ~= thisPos
        % update needed
        doUpdate = 1;
    end
    p.trial.display.grblPos = thisPos;
    
else
    % no current alternatives...assume position updated externally
    sn = '';
end


% shortcircuit
if ~doUpdate
    return
end

    
%% Update physical positioning
switch sn
    case 'grbl'
        % Arduino CNC controller for ViewDist display stepper motors
        % (see:  www.github.com/czuba/grbl )
        % Move to the new position
        p.trial.(sn) = grbl.completeMove(p.trial.(sn), sprintf('G1 x%4.2f f%4.2f', p.trial.display.grblPos, 60/2),  .8);
                
    otherwise
        % do nothing, assume position updated externally
end


%% Update dependent variables

% 3D OpenGL rendering parameters
% if p.trial.display.useGL
    % Apply updated openGL params to viewport configuration
    % ALWAYS do this
    p.static.display.updateOpenGlParams();  % pdsDisplay METHOD (no longer a nested function)
% end


% Create new PLDAPS 'level' so that current viewdist params carry over to subsequent trials
updatePldapsDisplayParams(p);

% DEBUG
if debug
    fprintf('%3.3f\n', p.trial.display.ppd);
end


% % % % % % % % % % % 
%% Nested Functions
% % % % % % % % % % % 


%% updatePldapsDisplayParams(p)
    function updatePldapsDisplayParams(p)
        
        %   ------------------------
        % Necessary evil to allow these parameter changes to carry over to subsequent trials
        % Poll current pldaps 'levels' state (...crappy params class stuff)
        % Create new 'level', that contains all current .display settings
        % -- (overkill, but getting struct diff alone is a nightmare)
        newLvlStruct = struct;
        newLvlStruct.display = p.static.display; % ? copy()
        
        % update overlay grid ticks & carry over to future trials
        initTicks(p);
        newLvlStruct.pldaps.draw.grid.tick_line_matrix = p.trial.pldaps.draw.grid.tick_line_matrix;
        
        
        %unlock the defaultParameters
        prevState = p.defaultParameters.setLock(false);
        % Create the new level
        p.defaultParameters.addLevels({newLvlStruct}, {sprintf('viewdistUpdateTrial%d', p.defaultParameters.pldaps.iTrial)});
        % append this new level to the baseParamsLevels
        p.static.pldaps.baseParamsLevels = [p.static.pldaps.baseParamsLevels, length(p.defaultParameters.getAllLevels)];
        
        
        %re-lock the defaultParameters
        p.defaultParameters.setLock(prevState);
        
    end


end %main function

