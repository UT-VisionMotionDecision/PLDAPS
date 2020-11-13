function p = pmMatrixGabs(p, state, sn)
% function p = pmMatrixGabs(p, state, sn)
% 
% demo PLDAPS module ("pm") for drawing set of gabors
% PLDAPS ver. >=4.3 (glDraw) recommended  (ver. 4.2...YMMV)
% 
% Dependencies:
%     visBasics.     .m
%     pds.applyDefaults.m
%     PLDAPS/SupportFunctions/Utils/gaborShader.*          
%
% 2018-xx-xx  TBC  Wrote it
% 2020-10-16  TBC  Gabor positioning update:
%                  - NEW [.centerOnScreen] flag to use screen center as origin,
%                  -- destRect texture coords now consistent with Screen('DrawDots'..)

% ---------------------------------------------------------------- 
% Stimulus position & screen center:
% Stimulus rendering coordinates of PTB & OpenGL can be confusing/conflicting from
% time to time.
% PTB's default places the origin in the upper left corner of the screen, with
% the positive Y-axis in the downward direction.
% 
% OpenGL (*logically*) places the origin at the center of the screen, with
% the positive Y-axis in the upward direction.
% (+x,+y) is in the upper right quadrant
% (-x,-y) is in the lower left quadrant.
% 
% This module attempts to rectify this discrepancy by aligning to the OpenGL
% coordinate frame. Because centering on screen involves both a shift & y-axis
% flip (relative to PTB pixel-centric coordinates) this leads to some crufty
% confusing code, but we've tried to minimize & streamline it as much as possible.
%   -- T.Czuba, Nov. 2020
% 
% ----------------------------------------------------------------

snBase = sn(1:end-2);
% base name by stripping off matrix module number (2 digits)
%  ...my own dumb coding. --TBC

% Flag operations that should only be done once across ALL matrixModule instances
oneTimers = contains(sn(end-1:end),'01');

switch state
    % FRAME STATES
    case p.trial.pldaps.trialStates.frameUpdate
            % [T]rack mouse position
            if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.tKey)
                p.trial.(snBase).trackMouse = true;
                
            elseif p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.rKey)
                % [R]emain in the same position (..?)
                p.trial.(snBase).trackMouse = false;
                try
                    mousePos = [1;-1].*(p.trial.mouse.cursorSamples(1:2,p.trial.mouse.samples)-p.trial.display.ctr(1:2)');
                    fprintf('Cursor Pos: %3.3f, %3.3f deg\n', pds.px2deg(mousePos, p.trial.display.viewdist, p.trial.display.px2w));
                end
                
            end
                        
            if p.trial.(snBase).trackMouse
                % dynamically update pixel position (else pixel position only computed at start of trial)
                updateGaborPosition(p, sn);
            end
            
            
    case p.trial.pldaps.trialStates.framePrepareDrawing
        if p.trial.(sn).on
            % Record stim position for this frame:   [xyz, element, frame]
            p.trial.(sn).posFrames(:,:,p.trial.iFrame) = p.trial.(sn).pos;

            % update stimulus dirs to track eye/cursor for this frame
            switch p.trial.(sn).type
                case {'cartGrid'}
                    % follow singular TF param
                    phaseStep = p.trial.(snBase).gabTf/p.trial.display.frate*360;

                case {'cart','polar'}
                    % follow individual TF param (e.g. IOC pattern motion components)
                    phaseStep = p.trial.(sn).gabTf/p.trial.display.frate*360;

                case {'polarTrack', 'cartTrack'}
                    % follow individual TF param (e.g. IOC pattern motion components)
                    phaseStep = p.trial.(sn).gabTf/p.trial.display.frate*360;
                    % center eyeXY on screen & convert to vis deg
                    eyeXY = [1;-1].*([p.trial.eyeX(1); p.trial.eyeY(1)] - p.trial.display.ctr(1:2)') ./ p.trial.display.ppd;
                    eyeXY(2,:) = -eyeXY(2,:); % correct sign of y-axis
                    iposrel = p.trial.(sn).pos - eyeXY;
                    % 
                    p.trial.(sn).dir = atan2d(iposrel(1,:), -iposrel(2,:)) +90;
                    
            end
                        
            % drift gabor phase
            for i = p.trial.display.bufferIdx
                % SAME direction in either eye
                p.trial.(sn).Gpars(1,:,i+1) = p.trial.(sn).Gpars(1,:,i+1) + phaseStep;
                % % opposite direction in either eye would be:
                % p.trial.(sn).Gpars(1,:,i+1) = p.trial.(sn).Gpars(1,:,i+1) + phaseStep * (-i*2+1);
            end
        end
        
        
    case p.trial.pldaps.trialStates.frameDraw
        if p.trial.(sn).on
            % must change blend function for procedural gabor rendering
            % ...only one BlendFunction to set, not separate for each stereobuffer.
            [prevSrcRect, prevDestRect] = Screen('BlendFunction', p.trial.display.ptr, 'GL_ONE', 'GL_ONE');
            drawTheGabors(p, sn);
            % reset previous blend functions
            Screen('BlendFunction', p.trial.display.ptr, prevSrcRect, prevDestRect);
        end
        
        % Draw stimulus markers on overlay screen
        if oneTimers && p.trial.(snBase).drawMarkers
            Screen('FrameOval', p.trial.display.overlayptr, p.trial.display.clut.blackbg, p.trial.(snBase).markerRects', 1);
        end

        
	% TRIAL STATES        
    case p.trial.pldaps.trialStates.trialPrepare
        % only do here what can't be done in conditions matrix
        trialPrepare(p, sn);
        
        
    % EXPT STATES
    case p.trial.pldaps.trialStates.experimentPreOpenScreen
        initParams(p, sn);

        
    case p.trial.pldaps.trialStates.experimentPostOpenScreen        
        % Create procedural textures
        %   -- input params assumed to be in visual degrees
        p = modularDemo.makeGaborsCentered(p, sn);
        
        
    case p.trial.pldaps.trialStates.experimentCleanUp
        Screen('Close', p.trial.(sn).gabTex);
        
end


%% Nested functions
    
    function p = updateGaborPosition(p, sn)
        
        % compute screen-centered mouse position
        if p.trial.(snBase).trackMouse && p.trial.mouse.samples>0
            % correct mouse pos to upright screen-centered coordinates (i.e. glDraw coordinates)
            % & convert to vis.deg
            stimCtr = [1;-1] .* (p.trial.mouse.cursorSamples(:,p.trial.mouse.samples) - p.trial.display.ctr(1:2)') ./ p.trial.display.ppd;%
        else
            stimCtr = p.trial.(snBase).stimCtr;
        end

        % Calculate/update gabor positions (in deg)
        switch p.trial.(sn).type
            case {'cartGrid'}
                for i = 1:2 % [x,y]
                    p.trial.(sn).pos(i,:) = ((p.trial.(sn).stimPos(i) * p.trial.(snBase).gridSz(i)) + stimCtr(i));
                end

            case {'cart', 'cartTrack'}
                for i = 1:2 % [x,y]
                    p.trial.(sn).pos(i,:) = (p.trial.(sn).stimPos(i) + stimCtr(i));
                    %NOTE: mouse samples don't exist yet in PLDAPS [trialPrepare] state (...not prior to sampling in pldapsDefaultTrial>>frameUpdate state)                    
                end

            case {'polar', 'polarTrack'}
                % largely defunct stim type...
                [p.trial.(sn).pos(1,:), p.trial.(sn).pos(2,:)] = pol2cart(deg2rad(-p.trial.(sn).stimPos(1)), p.trial.(sn).stimPos(2));

        end
        
        % Convert pos visual degrees to pixels
        p.trial.(sn).pos = p.trial.(sn).pos  .* p.trial.display.ppd;
        % NOTE on deg2pixel conversion:
        % Non-projection method here is intentional to maintain relative spacing/position onscreen;
        % - since projection warping not applied w/in procedurally drawn elements,
        %   simple .ppd scaling is preferred over something like pds.deg2px() for now


        % Gabor bounding rect:
        % - safest to maintain 1:1 mapping of source to destination rect
        % - inability to truly scale procedural texture srcRect poses unique challenge for [far] viewing distances
        %   ...may be forced to implement clever scaling/sub-sampling of rects here at somepoint. --TBC Nov 2020
        gabRect = p.trial.(sn).texRect;
        
        % update gabor rects to this positon
        p.trial.(sn).gabRects = CenterRectOnPointd( gabRect, p.trial.(sn).pos(1,:)', p.trial.(sn).pos(2,:)');
        %                 p.trial.(sn).gabRects = bsxfun(@plus, p.trial.(sn).gabRects, p.trial.display.ctr);
        
        % %         if oneTimers && p.trial.(snBase).drawMarkers
        % %             p.trial.(snBase).markerRects = unique([p.trial.(snBase).markerRects;  p.trial.(sn).gabRects], 'rows');
        % %         end

    end

%% trialPrepare
    function trialPrepare(p, sn)

        % Update gabor parameters & conversions (covers params set in procedural gabor creation function:  glDraw.makeGabors.m)
        % - necessary for gabor shape/size/sf parameter flexibility, and viewing distance dependence
        gabSd = p.trial.(snBase).gabFwhm ./ sqrt(8*log(2));
        if ~isequal(p.trial.(sn).gabSd, gabSd)
            p.trial.(sn).gabSd = gabSd;
        end
        p.trial.(sn).gabPixCycle    = p.trial.(sn).gabSf / p.trial.display.ppd;   % pix/deg * deg/cycle = pix/cycle
        p.trial.(sn).gabPixels      = 8 * p.trial.(sn).gabSd .* p.trial.display.ppd;
        p.trial.(sn).texSz          = ceil(p.trial.(sn).gabPixels);
        p.trial.(sn).texRect        = [0 0 1 1] * p.trial.(sn).texSz(:);
        
        p.trial.(sn).Gpars(2,:)     = p.trial.(sn).gabPixCycle;
        p.trial.(sn).Gpars(3,:)     = p.trial.(sn).gabSd * p.trial.display.ppd; % std of gaussian hull (in pixels)
                
        % update gabor rects based on position
        p = updateGaborPosition(p, sn);

        % Record position on a frame-by-frame basis:
        % - for analysis of data collected during dynamic stim update (.trackMouse == true)
        p.trial.(sn).posFrames = nan( [size(p.trial.(sn).pos), ceil(p.trial.pldaps.maxFrames)] );
        
        % Rects for overlay markers
        % - markerRects are stored/accumulated in snBase, and only drawn once (by [snBase, '01'])
        % - rects must be offset & y-flipped for [wonky] pixel-centric coordinate system of Screen('DrawTextures'...)
        % - NOTE:  This is disgusting & heavy...do not imitate!.
        if oneTimers
            switch p.trial.(sn).type
                case {'cartGrid'}
                    % plot markers for ALL stim locations in condMatrix
                    % Different process for RfPos grid...
                    %   ctrVars == [gridSize[x,y];  gridCenter[x,y];  pixPerDeg[x,-y];  screenCenter[x,y] ]
                    %              *!* this incorporates the Y-axis flip in ppd conversion [facepalm]
                    ctrVars = [p.trial.(snBase).gridSz; p.trial.(snBase).stimCtr(1:2); p.trial.display.ppd*[1 -1]; p.trial.display.ctr(1:2)];
                    % For each condition in condMatrix:
                    %   xy ==  ((<stimPos> .* gridSize) + gridCenter) * pixPerDeg + screenCenter;
                    xy = unique( cell2mat(cellfun(@(x) (x.stimPos.*ctrVars(1,:)+ctrVars(2,:)).*ctrVars(3,:)+ctrVars(4,:), p.condMatrix.conditions(:), 'uni',0)), 'rows');
                
                otherwise
                    % p.trial.(snBase).markerRects = p.trial.(sn).gabRects;
                    %   ctrVars == [stimCenter[x,y];  pixPerDeg[x,-y];  screenCenter[x,y] ]
                    %              *!* this incorporates the Y-axis flip in ppd conversion [facepalm]
                    ctrVars = [p.trial.(snBase).stimCtr(1:2); p.trial.display.ppd*[1 -1]; p.trial.display.ctr(1:2)];
                    % For each condition in condMatrix:
                    %   xy ==  ((<stimPos>) + gridCenter) * pixPerDeg + screenCenter;
                    xy = unique( cell2mat(cellfun(@(x) (x.stimPos+ctrVars(1,:)).*ctrVars(2,:)+ctrVars(3,:), p.condMatrix.conditions(:), 'uni',0)), 'rows');                    
            end
            % Create rect for marker == gabor FWHM
            % - this is distinctly smaller (& more informative) than rect used for rendering the gabor texture
            fwhmRect = p.trial.(snBase).gabFwhm * p.trial.display.ppd * [0 0 1 1];
            p.trial.(snBase).markerRects = CenterRectOnPointd(fwhmRect, xy(:,1), xy(:,2));

        end
        
        % Randomize initial phase
        p.trial.(sn).Gpars(1,:) = rand([1, p.trial.(sn).ngabors*numel(p.trial.display.bufferIdx)])*360;
        
        % If stereo, establish interocular phase
        if numel(p.trial.display.bufferIdx)>1
%             switch p.trial.(sn).binoPhaseMode
%                 case 0
                    % ZERO interocular phase difference (i.e. in plane of fixation)
                    p.trial.(sn).Gpars(1,:,2) = p.trial.(sn).Gpars(1,:,1);
%                 case 1
%                     % MATCHED random initial phase offset for all gabors
%                     ioPhaseDiff = diff(squeeze(p.trial.(sn).Gpars(1,1,:))); % use difference of first pair (...gives 1:1 link to fully random version)
%                     p.trial.(sn).Gpars(1,:,2) = p.trial.(sn).Gpars(1,:,1) + ioPhaseDiff;
%                 case 2
%                     % FULLY RANDOM initial phase offsets
%                     % do nothing
%             end
        end
        
    end % end trialPrepare


    %% initParams
    % Initialize default module parameters
    function initParams(p, sn)
        % list of default parameters
        def = struct(...
            'on', true ...
            ,'gabSd', .43 ...
            ,'gabSf', 2 ...
            ,'gabContrast', 1 ...
            ,'ngabors', 1 ...
            ,'pos', [0 0 0]' ...
            ,'dir', 0 ...
            ,'centerOnScreen', true ...
            ,'markerRects', [] ...
            ,'drawMarkers', false ...
            ,'trackMouse', false ...
            );
        
        % "pldaps requestedStates" for this module
        % - done here so that modifications only needbe made once, not everywhere this module is used
        rsNames = {'frameUpdate', 'framePrepareDrawing', 'frameDraw', ...
                   'trialPrepare', ...'trialCleanUpandSave', ...
                   'experimentPreOpenScreen', 'experimentPostOpenScreen', 'experimentCleanUp'};
               
        % Apply default params
        p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);
        p = pldapsModuleSetStates(p, sn, rsNames);
        
    end % end initParams
    

    %% drawTheGabors
    function drawTheGabors(p, sn)
        % .texRectCtr is centered on screen .display.
        if p.trial.(sn).on
            for i = p.trial.display.bufferIdx
                Screen('SelectStereoDrawBuffer',p.trial.display.ptr, i);
                Screen('DrawTextures', p.trial.display.ptr, p.trial.(sn).gabTex, [], p.trial.(sn).gabRects', p.trial.(sn).dir(:,min([i+1,end])), [], [], [], [], kPsychDontDoRotation, p.trial.(sn).Gpars(:,:,i+1));
            end
        end        
    end % end drawTheGabors
    

end