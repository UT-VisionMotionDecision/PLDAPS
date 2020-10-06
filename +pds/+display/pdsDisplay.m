classdef pdsDisplay < dynamicprops
    % PLDAPS display object
    
    %% Props:
    properties
        displayName
        scrnNum
        bgColor
        % physical dims
        screenSize      % pixel rect
        heightcm
        widthcm
        w2px
        px2w
        ipd
        %         % conversions
        %         widthPx
        %         heightPx
        %         widthDeg
        %         heightDeg
        
        
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
    end
    
    methods % Dependent get methods
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

        function ppd = get.ppd(obj)
            ppd = obj.winRect(4)/obj.height;
        end
        function cmpd = get.cmpd(obj)
            cmpd = 2*atand(0.5/obj.viewdist);
        end
        
        function glp = get.glPerspective(obj)
            glp = [atand(obj.heightcm/2 /obj.viewdist)*2,...
                obj.widthcm / obj.heightcm,...
                obj.zNear,...   % near clipping plane (cm)
                obj.zFar];      % far clipping plane (cm)
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
    events (ListenAccess = 'public')
        % change in .viewdist prop must update various dependents (ppd, widthDeg, heightDeg, etc)
        % & notify of other modules of update (i.e. tracking module for calibration update)
        viewDistSet
    end
    
    
    methods
        
        % Constructor
        function obj = pdsDisplay(varargin)
            
            p = varargin{1};
            % construct displayObj properties from PLDAPS struct
            fn = fieldnames(p.trial.display);
            % allow second input to initialize from existing pdsDisplay object (i.e. update existing)
            if nargin>1 && isa(varargin{2},'pdsDisplay')
                obj = varargin{2};
            end
%             pn = properties(obj);
            
            obj.updateFromStruct(p.trial.display)
            %             for i = 1:numel(fn)
            %                 % create prop if necessary
            %                 if ~ismember(fn{i},pn)
            %                     obj.addprop(fn{i});
            %                 end
            %                 % assign from struct
            %                 obj.(fn{i}) = p.trial.display.(fn{i});
            %             end
            
        end
        
        
        function updateFromStruct(obj, ds)
            % Update .display properties from [ds] input (i.e. p.trial.display)
            if isstruct(ds)
                % use struct fields to update object
                fn = fieldnames(ds);
                pn = properties(obj);
                for i = 1:length(fn)
                    if ismember(fn{i}, pn) && ~isempty(ds.(fn{i}))
                        if isempty(obj.(fn{i})) || ~all(eq(ds.(fn{i}),obj.(fn{i})))
                            obj.(fn{i}) = ds.(fn{i});
                        end
                    end
                end
            end
            
        end
        function testListener(obj)
            disp('.')
            notify(obj,'viewDistSet');
        end
            
        
    end %methods
    
end %classdef