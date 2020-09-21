function p = setViewdist(p, newdist)
% function p = setViewdist(p, newdist)
%
% Update any display variables that are dependent on viewing distance
%
% NOTE on [p.static] vs [p.trial]
% --This is confusing and way sub-optimal, but must have a way to convey
% status & info across trials. Things like physical distance aren't just
% "reset" when parameters for a new trial are initialized.
% p.static must only be used ONCE to compare current state (p.trial) against
% existing state (p.static), if different, correct & update.

%% defaults
debug = false;

doUpdate = 0;

if nargin>1
    % assign to active trial parameter
    p.trial.display.viewdist = newdist;
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
        p.trial.display.grblPos = thisPos;
    end
    
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
        
%         % Extract current values to p.static for future trial comparison
%         p.static.display.grblPos = p.trial.display.grblPos;
        
    otherwise
        % do nothing, assume position updated externally
end



%% Update dependent variables

% p.trial.display
% recompute any variables that are dependent on viewing distance
updateDisplayParams(p);

% 3D OpenGL rendering parameters
if p.trial.display.useGL
    % Apply updated openGL params to viewport configuration
    updateOpenGlParams(p.trial.display);  %nested function
end


% extract core/fundamental values to p.static for comparison in future trials
p.static.display.viewdist = p.trial.display.viewdist;


% DEBUG
if debug
    fprintf('%3.3f\n', p.trial.display.ppd);
end


% % % % % % % % % % % 
%% Nested Functions
% % % % % % % % % % % 


%% updateDisplayParams(p)
    function updateDisplayParams(p)
        viewdist = p.trial.display.viewdist;
        prevViewdist = p.static.display.viewdist;
        
        % Compute visual angle of the display (while accounting for any stereomode splits)
        switch p.trial.display.stereoMode
            case {2,3}
                % top-bottom split stereo
                p.trial.display.width   = 2*atand( p.trial.display.widthcm/2    /viewdist);
                p.trial.display.height  = 2*atand( p.trial.display.heightcm/4   /viewdist);
            case {4,5}
                % left-right split stereo
                p.trial.display.width   = 2*atand( p.trial.display.widthcm/4    /viewdist);
                p.trial.display.height  = 2*atand( p.trial.display.heightcm/2   /viewdist);
            otherwise
                p.trial.display.width   = 2*atand( p.trial.display.widthcm/2    /viewdist);
                p.trial.display.height  = 2*atand( p.trial.display.heightcm/2   /viewdist);
        end
        p.trial.display.ppd = p.trial.display.winRect(4)/p.trial.display.height; % calculate pixels per degree
        p.trial.display.cmpd = 2*atand(0.5/viewdist); % cm per degree at viewing distance line of sight
        % visual [d]egrees          % updated to ensure this param reflects ppd (i.e. not an independent/redundant calculation)
        p.trial.display.dWidth =  p.trial.display.pWidth/p.trial.display.ppd;
        p.trial.display.dHeight = p.trial.display.pHeight/p.trial.display.ppd;
        
        p.trial.display.fixPos(3) = viewdist;
        
        % depth clipping planes (zNear & zFar) should really be adjusted here too,
        % to ensure depth clipping doesn't occur unexpectedly
        p.trial.display.zNear = p.trial.display.zNear;
        % set far limit at consistent deg visual disparity for new viewing distance
        farDisp = p.trial.display.ipd*(prevViewdist-p.trial.display.zFar) / (prevViewdist*p.trial.display.zFar);
        p.trial.display.zFar = (farDisp * viewdist^2) / (p.trial.display.ipd - farDisp*viewdist);
        
        % compile glPerspective input parameters based on new geometry
        p.trial.display.glPerspective = [atand(p.trial.display.wHeight/2/viewdist)*2,...
            p.trial.display.wWidth/p.trial.display.wHeight,...
            p.trial.display.zNear,... % near clipping plane (cm)
            p.trial.display.zFar];  % far clipping plane (cm)
        
        
        %   ------------------------        
        % Necessary evil to allow these parameter changes to carry over to subsequent trials
        % Poll current pldaps 'levels' state (...crappy params class stuff)
        % Create new 'level', that contains all current .display settings
        % -- (overkill, but getting struct diff alone is a nightmare)
        newLvlStruct = struct;
        newLvlStruct.display = p.trial.display;
        
        %unlock the defaultParameters
        prevState = p.defaultParameters.setLock(false);
        % Create the new level
        p.defaultParameters.addLevels({newLvlStruct}, {sprintf('viewdistUpdateTrial%d', p.defaultParameters.pldaps.iTrial)});
        % append this new level to the baseParamsLevels
        p.static.pldaps.baseParamsLevels = [p.static.pldaps.baseParamsLevels, length(p.defaultParameters.getAllLevels)];
        
        
        %re-lock the defaultParameters
        p.defaultParameters.setLock(prevState);
        
    end


%% updateOpenGlParams(p.trial.display)
    function updateOpenGlParams(ds)
        global GL
        
        % readibility & avoid digging into this struct over & over
        glP = ds.glPerspective;
        
        % Setup projection matrix for each eye
        % (** this does not change per-eye, so just do it once here)
        % -- these context switches are slow and should NOT be done w/in time-dependent phases(e.g. during experimentPostOpenScreen, trialSetup...)
        Screen('BeginOpenGL', ds.ptr)
        
        for view = 0%:double(ds.stereoMode>0)
            % All of these settings will apply to BOTH eyes once implimented
            
            % Select stereo draw buffer WITHIN a 3D openGL context!
            % unbind current FBOS first (per PTB source:  "otherwise bad things can happen...")
            glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, uint32(0))
            
            % Bind this view's buffers
            fbo = uint32(view+1);
            glBindFramebufferEXT(GL.READ_FRAMEBUFFER_EXT, fbo);
            glBindFramebufferEXT(GL.DRAW_FRAMEBUFFER_EXT, fbo);
            glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, fbo);
            
            
            % Setup projection for stereo viewing
            glMatrixMode(GL.PROJECTION)
            glLoadIdentity;
            % glPerspective inputs: ( fovy, aspect, zNear, zFar )
            gluPerspective(glP(1), glP(2), glP(3), glP(4));
            
            % Enable proper occlusion handling via depth tests:
            glEnable(GL.DEPTH_TEST);
            
            % Enable alpha-blending for smooth dot drawing:
            glEnable(GL.BLEND);
            glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
            
            % 3D anti-aliasing?
            % NOTE: None of the standard smoothing enables improve rendering of gluDisk or sphere.
            % Only opening PTB window with multisampling (==4) has any effect
            
            % basic colors
            glClearColor(ds.bgColor(1), ds.bgColor(2), ds.bgColor(3), 1);
            glColor4f(1,1,1,1);
            
            % Disable lighting
            glDisable(GL.LIGHTING);
            % glDisable(GL.BLEND);
            
            % % %             if ds.goNuts
            % % %                 % ...or DO ALL THE THINGS!!!!
            % % %                 % Enable lighting
            % % %                 glEnable(GL.LIGHTING);
            % % %                 glEnable(GL.LIGHT0);
            % % %                 % Set light position:
            % % %                 glLightfv(GL.LIGHT0,GL.POSITION, [1 2 3 0]);
            % % %                 % Enable material colors based on glColorfv()
            % % %                 glEnable(GL.COLOR_MATERIAL);
            % % %                 glColorMaterial(GL.FRONT_AND_BACK, GL.AMBIENT_AND_DIFFUSE);
            % % %                 glMaterialf(GL.FRONT_AND_BACK, GL.SHININESS, 48);
            % % %                 glMaterialfv(GL.FRONT_AND_BACK, GL.SPECULAR, [.8 .8 .8 1]);
            % % %             end
        end
        Screen('EndOpenGL', ds.ptr)
    end %setupGLPerspective

end %main function

