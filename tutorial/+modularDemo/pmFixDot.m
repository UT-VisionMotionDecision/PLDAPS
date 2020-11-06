function p = pmFixDot(p, state, sn)
% function p = visBasics.pmFixLock(p, state, sn)
%
% PLDAPS module ("pm") for stereo fixation lock stimulus element
%
% Dependencies:  visBasics.makeFixLockPldaps.m
%                pds.applyDefaults.m
%
%         0-2 	standard DrawDots type (square, anti-aliased, xtra-nice anti-aliased)
%         3-9   geodesic sphere resolution, n-3==icosahedron scale factor
%                   !!NOTE!! Requires OpenGL >= 3.3  (...only functional on Linux atm. --TBC Nov. 2017)
%                   [dotType]==[nSides]: 3==20, 4==80, 5==320, 6==1280, 7==5120, 8==20,480, 9==81,920 sides
%                   recommended: 5-6  (i.e. 320-1280 sides)
%         >=10  n-segments of a mercator sphere (...simple, but over-samples poles)
%                   recommended: 12-22;


switch state
    % FRAME STATES
    case p.trial.pldaps.trialStates.frameUpdate
        p.trial.(sn).eyePos = [p.trial.eyeX, p.trial.eyeY]';
        % pixel conversion for .fixPos & .fixLim  (nested function)
        updatePixelValues;
                
    case p.trial.pldaps.trialStates.frameDraw
        if ~p.trial.display.useGL
            drawTheFixation(p, sn);
        end
        % Render overlay components
        % FIXME:  correct offset for XYZ-space sign and observer position
        if p.trial.pldaps.draw.eyepos.use && p.trial.display.useOverlay
            % render fix limits in green if held, red if not
            fixWinCol = p.trial.display.clut.redbg - p.trial.(sn).isheld;
            if p.trial.(sn).mode==2 % circle mode
                Screen('FrameOval', p.trial.display.overlayptr, fixWinCol, p.trial.(sn).fixRect, 3);
            elseif p.trial.(sn).mode==1 % rect mode
                Screen('FrameRect', p.trial.display.overlayptr, fixWinCol, p.trial.(sn).fixRect, 3);
            end
        end
            
    case {p.trial.pldaps.trialStates.frameGLDrawLeft, p.trial.pldaps.trialStates.frameGLDrawRight}
        if p.trial.display.useGL
            drawGLFixation(p, sn);
        end
        
        % TRIAL STATES
    case p.trial.pldaps.trialStates.trialItiDraw
        % drawTheFixation(p, sn);  % maintain fixation during iti
        
    case p.trial.pldaps.trialStates.trialPrepare
        
        % use screen viewdist as depth param if none specified
        if numel(p.trial.(sn).fixPos)<3
            p.trial.(sn).fixPos(3) = p.trial.display.viewdist;
        end
        
        % fixation window rect
        %(must be done here to allow O.T.F. changes in fixLim)
        % pixel conversion for .fixPos & .fixLim  (nested function)
        updatePixelValues;

        
        % EXPT STATES
    case p.trial.pldaps.trialStates.experimentPreOpenScreen
        initParams(p, sn);
        
        
    case p.trial.pldaps.trialStates.experimentPostOpenScreen
        % pixel conversion for .fixPos & .fixLim  (nested function)
        %updatePixelValues; 
        
        % Shader path to local PLDAPS install if needed for geospheres
        % ...this is a shady/complex setup stage...FIXME
        if IsLinux && p.trial.(sn).dotType>2 && p.trial.(sn).dotType<10
            % linux geospheres
            p.trial.(sn).shaderPath = fullfile(p.trial.pldaps.dirs.proot,'SupportFunctions','Utils');
        else
            p.trial.(sn).shaderPath = [];
        end
        
    case p.trial.pldaps.trialStates.experimentCleanUp
        
        
end

%% Nested functions
%% initParams
% Initialize default module parameters
    function initParams(p, sn)
        % list of default parameters
        def = struct(...
            'on', true,...
            'mode', 2,...   % limit type (0==pass/none, 1==square, 2==euclidean/circle)
            'isheld',0,...  % current state of fixation
            'fixPos',[0 0],... % xyz position   [0 0 p.trial.display.viewdist]
            'dotSz',5,...   % fix dot size
            'col',[1 1 1 1]',...    % fix dot color [R G B A]
            'dotType',2,...    % use basic PTB anti-aliased dots by default
            'fixLim', [2 2]...  % fixation window (deg)
            );
        
        p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);
        % create static dot buffer fields in case (only needed if linux & rendering with dotType >2 & <10
        p.static.(sn).dotBuffers = [];
        
    end % end initParams


%% updatePixelValues
    function updatePixelValues
        % ???? should fixPos be inherited from 3D coords in .display.fixPos, since used there to define frustrum???
        % YES   for .fixPos(3),     which is in units of CM
        % NO    for .fixPos(1:2),   which are in units of visual degrees(!)
        % !!NOTE!!  Confusion with currentFixation .fixPos and pdsDisplay.fixPos
        %           - the latter is in CM, and is less clear how to [dynamically/flexibly] integrate with rendering
        %             of various PTB elements
        %
        p.trial.(sn).fixPos(3) = p.trial.display.viewdist;
        
        if p.trial.display.useGL
            % For XYZ-space, need to convert from cm to pixels
            % **** currently only xy coords are converted; Z not considered when rendering!
            [p.trial.(sn).fixPosCm(1:2), p.trial.(sn).fixPosCm(3)] = pds.deg2world(p.trial.(sn).fixPos(1:2), p.trial.(sn).fixPos(3), 1);
            p.trial.(sn).fixPosPx = pds.deg2px(p.trial.(sn).fixPos(1:2)', p.trial.(sn).fixPos(3), p.trial.display.w2px)'; % p.trial.(sn).fixPos(1:2) * diag(p.trial.display.w2px);
            % Adjust dot size to consistent visual angle across depth
            dotCm = p.deg2world(p, [p.trial.(sn).dotSz*[-.5,.5]; 0,0], p.trial.(sn).fixPos(3));
            p.trial.(sn).dotSzCm =  diff(dotCm(1,:));
            % fprintf('%8.3g\t', p.trial.(sn).dotSz); disp(p.trial.(sn).fixPosCm)
        else
            % dot size must be integer pixel value
            if p.trial.(sn).dotSz<1
                p.trial.(sn).dotSz = round(p.trial.(sn).dotSz * p.trial.display.ppd);
                %p.trial.(sn).dotType = 2;
            elseif mod(p.trial.(sn).dotSz,1)~=0
                p.trial.(sn).dotSz = round(p.trial.(sn).dotSz);
            end
            p.trial.(sn).fixPosPx = pds.deg2px(p.trial.(sn).fixPos(1:2)', p.trial.(sn).fixPos(3), p.trial.display.w2px)'; %p.trial.(sn).fixPos(1:2) * p.trial.display.ppd;
        end
        p.trial.(sn).fixLimPx = p.trial.(sn).fixLim * p.trial.display.ppd;
        p.trial.(sn).fixRect = CenterRectOnPointd( [-p.trial.(sn).fixLimPx([1,end]), p.trial.(sn).fixLimPx([1,end])], p.trial.(sn).fixPosPx(1)+p.trial.display.ctr(1), -p.trial.(sn).fixPosPx(2)+p.trial.display.ctr(2));

    end %updatePixelValues


%% drawTheFixation
    function drawTheFixation(p, sn)
        % .texRectCtr is centered on screen .display.
        if p.trial.(sn).on
            % error check dot type
            dt = p.trial.(sn).dotType;
            dt(dt>4) = 2; % dotType>4 generally due to a geodesic sphere quantity (pldapsDrawDotsGL.m), so fallback to a circular dot
            % draw to all available buffer(s)
            for i = p.trial.display.bufferIdx
                Screen('SelectStereoDrawBuffer',p.trial.display.ptr, i);
                % inverts y-axis for consistency
                Screen('DrawDots', p.trial.display.ptr, p.trial.(sn).fixPosPx(1:2)' .* [1;-1], p.trial.(sn).dotSz, p.trial.(sn).col, p.trial.display.ctr(1:2), dt);
            end
        end
    end %drawTheFixation


%% drawGLFixation
    function drawGLFixation(p, sn)
        %fprintf('%8.3g\t%s\n', p.trial.(sn).dotSzCm, mat2str(p.trial.(sn).fixPosCm, 3))
        if p.trial.(sn).on
            % Render dot in 3D space
            p.static.(sn).dotBuffers = pldapsDrawDotsGL(...    (xyz, dotsz, dotcolor, center3D, dotType, glslshader)
                p.trial.(sn).fixPosCm'...
                , p.trial.(sn).dotSzCm...
                , p.trial.(sn).col...
                , p.trial.display.obsPos(1:3)...
                , p.trial.(sn).dotType...
                , p.static.(sn).dotBuffers);
        end
    end %drawGLFixation

end
