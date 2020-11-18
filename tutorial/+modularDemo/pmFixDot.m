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
        
        if ~isempty(p.static.(sn).dotBuffers)
            % populate buffer params from p.static (to carryover across trials)
            p.trial.(sn).dotBuffers = p.static.(sn).dotBuffers;
        end
        
        % fixation window rect
        %(must be done here to allow O.T.F. changes in fixLim)
        % pixel conversion for .fixPos & .fixLim  (nested function)
        updatePixelValues;
        
        
    case p.trial.pldaps.trialStates.trialCleanUpandSave
        if ~isempty(p.trial.(sn).dotBuffers)
            % reuse dotBuffers by passing them through p.static between trials
            p.static.(sn).dotBuffers = p.trial.(sn).dotBuffers;
        end
        
        
        % EXPT STATES
    case p.trial.pldaps.trialStates.experimentPreOpenScreen
        initParams(p, sn);
        
        
    case p.trial.pldaps.trialStates.experimentPostOpenScreen
        % pixel conversion for .fixPos & .fixLim  (nested function)
        %updatePixelValues; 
        
        % Shader path to local PLDAPS install if needed for geospheres
        p.trial.(sn).shaderPath = [];
        if IsLinux && p.trial.(sn).dotType>2 && p.trial.(sn).dotType<10
            % linux geospheres
            p.trial.(sn).shaderPath = fullfile(p.trial.pldaps.dirs.proot,'SupportFunctions','Utils');
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
            'fixLim', [2 2],...  % fixation window (deg)
            'dotBuffers', []...
            );
        % "pldaps requestedStates" for this module
        % - done here so that modifications only needbe made once, not everywhere this module is used
        rsNames = {'frameUpdate','frameDraw','frameGLDrawLeft','frameGLDrawRight', ...
                   'trialItiDraw','trialPrepare','trialCleanUpandSave', ...
                   'experimentPreOpenScreen','experimentPostOpenScreen','experimentCleanUp'};
        
        % Apply default params
        p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);
        p = pldapsModuleSetStates(p, sn, rsNames);
        
        % create static dot buffer fields in case (only needed if linux & rendering with dotType >2 & <10
        p.static.(sn).dotBuffers = p.trial.(sn).dotBuffers; % initialized as []
        
    end % end initParams


%% updatePixelValues
    function updatePixelValues
        % ???? should fixPos be inherited from 3D coords in .display.fixPos,
        % since used there to define frustrum???  ...or vice versa?
        %
        % !!NOTE!! Something still not quite syncing up with fixation lim & location when
        %          fixation z location is ~= viewdist. Doesn't currently come up, but 
        %          in need of attention.  --TBC 2020
        
        if p.trial.display.useGL
            % For XYZ-space, need to convert from deg/cm to pixels
            [p.trial.(sn).fixPosCm(1:2), p.trial.(sn).fixPosCm(3)] = pds.deg2world(p.trial.(sn).fixPos(1:2), p.trial.(sn).fixPos(3), 1);
            p.trial.(sn).fixPosPx = pds.deg2px(p.trial.(sn).fixPos(1:2)', p.trial.(sn).fixPos(3), p.trial.display.w2px, 1)';
            % Adjust dot size to consistent visual angle across depth
            dotCm = p.deg2world(p, [p.trial.(sn).dotSz*[-.5,.5]; 0,0], p.trial.(sn).fixPos(3));
            p.trial.(sn).dotSzCm =  diff(dotCm(1,:));
            % fprintf('%8.3g\t', p.trial.(sn).dotSz); disp(p.trial.(sn).fixPosCm)
        else
            % dot size must be integer pixel value
            if p.trial.(sn).dotSz<1
                p.trial.(sn).dotSz = round(p.trial.(sn).dotSz * p.trial.display.ppd);
            elseif mod(p.trial.(sn).dotSz,1)~=0
                p.trial.(sn).dotSz = round(p.trial.(sn).dotSz);
            end
            
            % **** Z not considered when rendering only in 2D
            p.trial.(sn).fixPosPx = pds.deg2px(p.trial.(sn).fixPos(1:2)', p.trial.display.viewdist, p.trial.display.w2px, 0)'; %p.trial.(sn).fixPos(1:2) * p.trial.display.ppd;
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
            % Compute rendering center based on viewport
            % - see dotCenter usage in pldapsDrawDotsGL.m
            dotCenter = p.trial.display.obsPos; dotCenter(1,4) = nan; % translation to observer pos 
            dotCenter(2,:) = [p.trial.display.fixPos(:); nan]'; % translate to WORLD fixation pos
            % **NOTE: Inclusion of .obsPos translation may be unnecessary/unwanted
            %         ...circa 2020, obsPos has virtually always been [0,0,0] so largely untested
            
            % Adjust envirocentric dot positions relative to rendering location
            dotXyzCm = (p.trial.(sn).fixPosCm - p.trial.display.fixPos)'; % Subtract off fixation position

            % Render dot in 3D space
            p.trial.(sn).dotBuffers = pldapsDrawDotsGL(...    (xyz, dotsz, dotcolor, center3D, dotType, glslshader)
                dotXyzCm ... p.trial.(sn).fixPosCm'
                , p.trial.(sn).dotSzCm ...
                , p.trial.(sn).col ...
                , dotCenter ...p.trial.display.obsPos(1:3) ...
                , p.trial.(sn).dotType ...
                , p.trial.(sn).shaderPath ...
                , p.trial.(sn).dotBuffers);
        end
    end %drawGLFixation

end
