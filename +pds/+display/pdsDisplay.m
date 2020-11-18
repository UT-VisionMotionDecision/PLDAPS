classdef pdsDisplay < dynamicprops
    % PLDAPS display object
    
    %% Props:
    properties
        displayName
        scrnNum
        bgColor
        % Physical dimensions
        screenSize      % pixel rect
        heightcm
        widthcm
        w2px
        px2w
        ipd        
        
        % PTB & openScreen params
        ptr
        winRect = zeros(1,4);
        ctr
        bufferIdx
        stereoMode
        multisample
        colorclamp
        forceLinearGamma
        normalizeColor
        sourceFactorNew
        destinationFactorNew
        stereoFlip
        gamma
        info
        
        % PLDAPS params
        useOverlay
        overlayptr
        overlaytex
        shader
        overlayShaderIdx
        preOpenScreenFxn
        postOpenScreenFxn
        switchOverlayCLUTs %depricate?
        rb3d
        crosstalk
        homeDist
        grblPos
        useGL
        clut
        white
        black
        humanCLUT
        monkeyCLUT
        t0
        
    end %properties
    
    properties (Dependent, SetAccess = private)
        width   %Deg
        height  %Deg
        ppd
        cmpd
        glPerspective
        widthPx
        heightPx
        widthDeg
        heightDeg
    end
    
    properties (Hidden, Access = private, Transient)
        p % handle to overarching PLDAPS object
    end
    
    methods % Dependent 'get' methods
        function width = get.width(obj)
            width   = 2*atand( obj.widthcm/2    /obj.viewdist);
        end
        function height = get.height(obj)
            height  = 2*atand( obj.heightcm/2  /obj.viewdist);
        end
        function wpx = get.widthPx(obj)
            wpx     = diff(obj.winRect([1,3]));
        end
        function hpx = get.heightPx(obj)
            hpx     = diff(obj.winRect([2,4]));
        end
        function wpx = get.widthDeg(obj)
            wpx     = obj.width;
        end
        function hpx = get.heightDeg(obj)
            hpx     = obj.height;
        end

        function ppd = get.ppd(obj)
            ppd = obj.winRect(4)/obj.height;
        end
        function cmpd = get.cmpd(obj)
            cmpd = 2*atand(0.5/obj.viewdist);
        end
        
        function glp = get.glPerspective(obj)
            glp = [atand(obj.heightcm/2 /obj.viewdist)*2,... FOV in Y (deg, determines height)
                   obj.widthcm / obj.heightcm,... XY Aspect ratio (determines width)
                   obj.zNear,...   % near clipping plane (cm, always positive)
                   obj.zFar];      % far clipping plane (cm, always positive)
        end
    end
    
    %% Prop:  SetObservable
    properties (SetObservable, AbortSet, GetObservable)
        % physical viewing distance
        viewdist
        % OpenGL viewport geometry
        fixPos
        obsPos
        upVect
        zNear
        zFar
    end
    
    
    %% Events: Public
    % % These props now setup as explicit dependencies
    % %     events (ListenAccess = 'public')
    % %         % change in .viewdist prop must update various dependents (ppd, widthDeg, heightDeg, etc)
    % %         % & notify of other modules of update (i.e. tracking module for calibration update)
    % %         viewDistSet
    % %     end
    
    
    methods
        
        %% Constructor: obj = pdsDisplay(pldapsObj)
        function obj = pdsDisplay(varargin)
            
            p = varargin{1};
            obj.p = p;
            % construct displayObj properties from PLDAPS struct
            fn = fieldnames(p.trial.display);
            % allow second input to initialize from existing pdsDisplay object (i.e. update existing)
            if nargin>1 && isa(varargin{2},'pdsDisplay')
                obj = varargin{2};
            end
%             pn = properties(obj);
            
            obj.updateFromStruct(p.trial.display)
            
            % .viewdist property PostSet listener needed here
            addlistener(obj,'viewdist','PostSet', @obj.viewDistSet);
            % On change:
            % - check for active positioning modules (.grbl) that need triggering/updating
            % - check for tracking module/object calibration update
            % -- update calibration transform using fixation data for this viewing distance
            % -- if no data from this distance, figure out how to trigger a calibration trial
            % --- currently need to enter PLDAPS pause state, then execute pds.tracking.runCalibrationTrial(p)
            % --- programmatic trigger will fix bottleneck here, and in first trial startup.
            
        end
        
        %% updateFromStruct
        function updateFromStruct(obj, ds)
            % function updateFromStruct(obj, ds)
            % Update pdsDisplay properties from [ds] fields (i.e. p.trial.display)
            % [ds] == p.trial.display
            if isstruct(ds)
                % use struct fields to update object
                fn = fieldnames(ds);
                pn = properties(obj);
                for i = 1:length(fn)
                    if ismember(fn{i}, pn) && ~isempty(ds.(fn{i}))
                        if isempty(obj.(fn{i})) || ~isequal(ds.(fn{i}),obj.(fn{i}))
                            obj.(fn{i}) = ds.(fn{i});
                        end
                    end
                end
            end
            
        end
        
        
        %% syncToTrialStruct(obj, ds)
        function ds = syncToTrialStruct(obj, ds)
            % function syncToTrialStruct(obj, ds)
            % Update [ds] struct fields with pdsDisplay object properties
            % [ds] == p.trial.display
            fn = fieldnames(ds);
            pn = properties(obj);
            for i = 1:length(pn)
                if ismember(pn{i}, fn) && ~isequal(obj.(pn{i}),ds.(pn{i})) %&& ~isempty(obj.(pn{i}))
                    % copy object property value to display struct[ds]
                    ds.(pn{i}) = obj.(pn{i});
                else
                    % create new struct field for this property (..unexpected)
                    ds.(pn{i}) = obj.(pn{i});
                end
            end
        end %syncToTrialStruct
        
        
        %% testListener(obj)
        function viewDistSet(obj, varargin)
            % when triggered by listener, varargin will be {1}src, and {2}evnt
            % but since this is self triggered, obj is enough
            if nargin<3
                o = varargin{end}.AffectedObject;
            else
                o = obj;
            end
            disp('.')
            
            % ensure .display.fixPos(3) == viewdist
            o.fixPos(3) = o.viewdist;
            % Update OpenGL params
            %   (~~~ WARNING ~~~: potentially slow OpenGL context switching)
            o.updateOpenGlParams();

            % TODO:  Check for modules & active states in p.trial here....
            if isprop(o,'p') && isfield(o.p.static, 'tracking')
                % update OOP tracking object calibration
                o.p.static.tracking.updateTform();
            end
            %
            % .grbl
            % 
            % .tracking
            % 
            %
        end
            
        
        %% updateOpenGlParams(p.trial.display)
        function updateOpenGlParams(obj)
            
            global GL
            
            % readibility & avoid digging into this struct over & over
            glP = obj.glPerspective;
            
            % This can be triggered by a listener, so we need to be careful about what OpenGL mode we're in at time of call
            [~, IsOpenGLRendering] = Screen('GetOpenGLDrawMode');
            % -- these context switches are slow and should NOT be done w/in time-dependent phases(e.g. during experimentPostOpenScreen, trialSetup...)
            if ~IsOpenGLRendering
                Screen('BeginOpenGL', obj.ptr)
            end
            
            % Setup projection matrix for each eye
            % (** this does not change per-eye, so just do it once here)
            
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
                glClearColor(obj.bgColor(1), obj.bgColor(2), obj.bgColor(3), 1);
                glColor4f(1,1,1,1);
                
                % Disable lighting
                glDisable(GL.LIGHTING);
                % glDisable(GL.BLEND);
                
                % %                     % ...or DO ALL THE THINGS!!!!
                % %                     % Enable lighting
                % %                     glEnable(GL.LIGHTING);
                % %                     glEnable(GL.LIGHT0);
                % %                     % Set light position:
                % %                     glLightfv(GL.LIGHT0,GL.POSITION, [1 2 3 0]);
                % %                     % Enable material colors based on glColorfv()
                % %                     glEnable(GL.COLOR_MATERIAL);
                % %                     glColorMaterial(GL.FRONT_AND_BACK, GL.AMBIENT_AND_DIFFUSE);
                % %                     glMaterialf(GL.FRONT_AND_BACK, GL.SHININESS, 48);
                % %                     glMaterialfv(GL.FRONT_AND_BACK, GL.SPECULAR, [.8 .8 .8 1]);
            end
            
            if ~IsOpenGLRendering
                Screen('EndOpenGL', obj.ptr)
            end
            
        end %updateOpenGlParams
        
        
    end %methods
    
    
end %classdef