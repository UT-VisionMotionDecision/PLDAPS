function p = runCalibrationTrial(p, state, sn)
% function p = pds.tracking.runCalibrationTrial(p, state, sn)


if nargin<3 || isempty(sn)
    sn = 'tracking';
end

if nargin<2 || isempty(state)
    % special case to initiate calibration trial(s) from pause state
    if isfield(p.trial.(sn), 'on') && ~p.trial.(sn).on
        % set tracking calibration module on, & disable all modules with order > tracking module
        startCalibration;%(p, sn);
        return
        
    elseif isfield(p.trial.(sn), 'on') && p.trial.(sn).on
        % turn tracking calibration module off, & reenable module state prior to calibration phase
        finishCalibration;%(p, sn);
        return
    else
        % get list of currently active modules
        [moduleNames, fxnHandles] = getModules(p, 1);
        p.trial.(sn).tmp.initialActiveModules = moduleNames;
        
    end
end


%% PLDAPS state-switch block
switch state
    % FRAME STATES
    
    %--------------------------------------------------------------------------
    %     case p.trial.pldaps.trialStates.experimentPreOpenScreen
    
    
    %     %--------------------------------------------------------------------------
    %     % --- After screen is open: Setup default parameters
    case p.trial.pldaps.trialStates.experimentPostOpenScreen
        initParams(p, sn);
        
        %--------------------------------------------------------------------------
        % --- Trial Setup: pre-allocate important variables for storage and
        % update the object
        % TRIAL STATES
    case p.trial.pldaps.trialStates.trialItiDraw
        % drawTheFixation(p, sn);  % maintain fixation during iti
        
    case p.trial.pldaps.trialStates.trialPrepare
        
        % NOPE: This change fails to carry over to next trial. Must be set within a new params class active state (ugh..)
        %       HAK: equiv functionality triggered when runCalibrationTrial is called with nargin<2 or empty 'state' input
        %
        % %         if p.trial.(sn).on
        % %
        % %             % disable any other active modules
        % %             [moduleNames] = getModules(p, 1);
        % %             thisModuleIndex = find(strcmp(moduleNames,'tracking'));
        % %             % turn off all subsequent modules
        % %             for i = thisModuleIndex+1:length(moduleNames)
        % %                 p.trial.(moduleNames{i}).use = false;
        % %             end
        % %         end
        
        % clean up this code when working
        % % %         % fixation window rect overlay
        % % %         %(must be done here to allow O.T.F. changes in fixLim)
        % % %         % pixels
        % % %         if p.trial.display.useGL
        % % %             % For XYZ-space, need to convert from cm to pixels
        % % %             p.trial.(sn).targPosPx = p.trial.(sn).targPos(1:2) * diag(p.trial.display.w2px);
        % % %         else
        % % %             p.trial.(sn).targPosPx = p.trial.(sn).targPos(1:2) * p.trial.display.ppd;
        % % %         end
        % % %
        % % %         p.trial.(sn).fixLimPx = p.trial.(sn).fixLim(1:2) * p.trial.display.ppd;
        % % %         p.trial.(sn).fixRect = CenterRectOnPoint( [-p.trial.(sn).fixLimPx, p.trial.(sn).fixLimPx], p.trial.(sn).targPosPx(1)+p.trial.display.ctr(1), p.trial.(sn).targPosPx(2)+p.trial.display.ctr(2));
        
    case p.trial.pldaps.trialStates.trialSetup
        if p.trial.(sn).on
            
            %             % disable any other active modules
            %             [moduleNames] = getModules(p, 1);
            %             thisModuleIndex = find(strcmp(moduleNames,'tracking'));
            %             % turn off all subsequent modules
            %             for i = thisModuleIndex+1:length(moduleNames)
            %                 p.trial.(moduleNames{i}).use = false;
            %             end
            
            if ~isfield(p.trial.tracking, 'cm0') || isempty(p.trial.tracking.cm0)
                % bino compatible
                
                p.trial.tracking.cm0 = p.trial.tracking.calib.matrix; %repmat([1 0; 0 1; 0 0], [1,1,numel(p.trial.(sn).eyeIdx)]);    %[1 0; 0 1; 0 0];
            end
            
            % targX, targY, eyeX, eyeY, distance
            % targetXZY = real(p.trial.(sn).fixations);
            % eyeXYZ = imag(p.trial.(sn).fixations);
            if ~isfield(p.static.tracking,'fixations')
                p.static.tracking.fixations = nan(3, p.trial.tracking.maxSamples);   %nan(4, p.trial.(sn).maxSamples);
                p.static.tracking.thisFix = 0;
            end%else
            updateCalibTransform(p)
            %end
            
            p.trial.tracking.targets = setupTargets(p);
            updateTarget(p);
            
            if ~isfield(p.trial.tracking, 'cm')
                p.trial.tracking.cm = p.trial.tracking.cm0;
            end
            
            updateCalibPlot(p);
            
            printDirections;
        end
        
        
        %--------------------------------------------------------------------------
        % --- Manage stimulus before frame draw
    case p.trial.pldaps.trialStates.framePrepareDrawing %frameUpdate
        if p.trial.(sn).on
                        
            % Some standard PLDAPS key functions
            if any(p.trial.keyboard.firstPressQ)
                
                if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.escKey) || p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.xKey)
                    % [esc,x] exit calibration (or [X] key for macbook touchbar compat)
                    p.trial.tracking.on = false;
                    p.trial.flagNextTrial = true;
                    
                    
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.fKey)
                    % [f,F] key - log fixation
                    logFixation(p);
                    if p.trial.keyboard.modKeys.shift
                        % [F] ...and move to next random target
                        p.trial.tracking.nextTarg = p.trial.tracking.targets.randOrd(mod(p.static.tracking.thisFix,p.trial.tracking.targets.nTargets)+1);
                        updateTarget(p);
                        updateCalibPlot(p);
                    end
                    
                    
                elseif p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.spaceKey)
                    % [SPACEBAR] - log fixation & move to next random target (...same as shift-f [F])
                    logFixation(p);
                    updateTarget(p);
                    updateCalibPlot(p);
                    
                    
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.uKey)
                    % [u, U] key - update calibration matrix
                    updateCalibTransform(p);
                    updateCalibPlot(p);

                    
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.tKey)
                    % [T] key - update targets (i.e. change target w/o logging fixation)
                    p.trial.tracking.col(4) = 1;
                    updateTarget(p)
                    %                 p.trial.tracking.i
                    %                 p.trial.(sn).iTarget = p.trial.(sn).iTarget + 1;
                    %                 p.trial.(sn).targets(p.trial.(sn).iTarget) = setupTargets(p);
                    
                    % [ZERO] key - blank targets
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.zerKey) || p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.KPzerKey)
                    
                    if ~p.trial.tracking.col(4)
                        p.trial.tracking.col(4) = 1;
                    else
                        p.trial.tracking.col(4) = 0;
                    end
                    
                    % [E] key - remove last fixation
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.eKey)
                    % [SHIFT-E] to reset calibration altogether!
                    if p.trial.keyboard.modKeys.shift
                        p.static.tracking.fixations = nan(3, p.trial.tracking.maxSamples);   %nan(4, p.trial.(sn).maxSamples);
                        p.static.tracking.thisFix = 0;
                        p.trial.tracking.targets = setupTargets(p);
                        updateTarget(p);
                        updateCalibPlot(p);
                        % TODO:  ideally use modKey to only erase calibration points for current viewdist
                    else
                        p.static.tracking.thisFix = p.static.tracking.thisFix - 1;
                        p.trial.tracking.cm = p.trial.tracking.cm0;
                    end
                    
                    % [1-9] Jump to specified target location
                elseif  ~isempty(p.trial.keyboard.numKeys.pressed)   %(p.trial.keyboard.codes.oneKey)
                    if p.trial.keyboard.numKeys.pressed(end)>0
                        p.trial.tracking.nextTarg = p.trial.keyboard.numKeys.pressed(end);
                        disp(p.trial.tracking.nextTarg)
                        updateTarget(p)
                    end
                    
                end
            end
        end
        
        
        %--------------------------------------------------------------------------
        % --- Draw the frame
    case p.trial.pldaps.trialStates.frameDraw
        if p.trial.(sn).on
            
            % Pulsating target dot
            sz = p.trial.tracking.dotSz + abs(p.trial.tracking.dotSz*sin(p.trial.ttime*6));
                        
            % Screen('DrawDots', p.trial.display.ptr, targPx, sz, p.trial.tracking.col, [], 2);
%             if ~p.trial.display.useGL
                % Show target on subject screen
                targPx = p.trial.tracking.targets.xyPx(:,p.trial.tracking.targets.i);
                % nested fxns have access to this workspace...no inputs needed
                drawTheFixation; %(p, sn);
%             end
            
            if p.trial.pldaps.draw.eyepos.use && p.trial.display.useOverlay
                % show past & current eye position on screen
                if p.static.tracking.thisFix > 0
                    pastFixPx = transformPointsForward(p.trial.tracking.tform, imag(p.static.tracking.fixations(1:2, 1:p.static.tracking.thisFix))')';
                    Screen('DrawDots', p.trial.display.overlayptr, pastFixPx(1:2,:), 9, [0 1 0 .7], [], 0);
                end
                
                newEye = transformPointsForward(p.trial.tracking.tform, p.trial.tracking.posRaw')';%p.trial.tracking.cm * p.trial.tracking.eyeRaw;
                for i = 1:size(newEye,2)
                    % Screen('DrawDots', p.trial.display.overlayptr, newEye(1:2), 5, [0 1 0 1]', [], 0);
                    Screen('DrawDots', p.trial.display.overlayptr, newEye(1:2, i), 5, p.trial.display.clut.(['eye',num2str(i)]), [], 0);
                end

                
            end
        end
        
        
        % TODO:  for 3D rendering, target & eye coords need to be in CM
        % % %     case {p.trial.pldaps.trialStates.frameGLDrawLeft, p.trial.pldaps.trialStates.frameGLDrawRight}
        % % %         if p.trial.display.useGL
        % % %             % nested fxns have access to this workspace...no inputs needed
        % % %             drawGLFixation%(p, sn);
        % % %         end
        
        %--------------------------------------------------------------------------
        
        
        % --- After the trial: cleanup workspace for saving
    case p.trial.pldaps.trialStates.trialCleanUpandSave
        if p.trial.(sn).on
            p.static.tracking.fixations = p.static.tracking.fixations(:, 1:p.static.tracking.thisFix);
            updateCalibTransform(p);
            updateCalibPlot(p);
            
            p.trial.tracking.cm0 = p.trial.tracking.cm;
            
            if isfield(p.trial.tracking,'tform')
                p.static.tracking.calib.matrix = p.trial.tracking.tform;
            else
                p.static.tracking.calib.matrix = projective2d(p.trial.tracking.cm);
            end
            
            pds.tracking.updateMatrix(p);
            
            finishCalibration;
            % updateCalibPlot(p);
        end
        
end %state switch block


%% Nested functions
% have access to all local variables (no need to pass inputs/outputs unless special case)

%% startCalibration;
    function startCalibration
        % get list of currently active modules
        [moduleNames, fxnHandles] = getModules(p, 1);
        p.trial.(sn).tmp.initialActiveModules = moduleNames;
        
        find(strcmp(moduleNames,'tracking'));
        % disable any other active modules
        thisModuleIndex = find(strcmp(moduleNames, sn));
        % turn off all subsequent modules
        for i = thisModuleIndex+1:length(moduleNames)
            p.trial.(moduleNames{i}).use = false;
        end
        
        p.trial.(sn).on = true;
        
        % Programmatically resume from pause
        com.mathworks.mlservices.MLExecuteServices.consoleEval('dbcont');
        
    end %startCalibration


%% finishCalibration;
    function finishCalibration
        % oh great! Now how do we pause from here,
        % re-enable initial module activity state [in the p.run workspace?],
        % then return control to user in the pause state again??
        
        %tmp = p.trial.(sn).tmp;
        
        
        
        %!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!
        % (....wtf!?? So archaic& cryptic!  MUST GTF AWAY from this params class business!!
        %!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!
        
        
        
        % Poll current pldaps 'levels' state (...goofy params class stuff)
        %         lvlAll = p.defaultParameters.getAllLevels;
        %         lvlActive = p.defaultParameters.getActiveLevels;
        lvlAll = p.trial.pldaps.allLevels;
        lvlActive = p.trial.pldaps.activeLevels;
        
        % Create new 'level', that re-enables modules that were active when this calibration started
        newLvlStruct = struct;
        fn = p.trial.(sn).tmp.initialActiveModules;
        for i = 1:length(fn)
            newLvlStruct.(fn{i}).use = true;
        end
        % turn this module off in that new level
        newLvlStruct.(sn).on = false;
        
        %   **NOTE: .on ~= .use !!
        %   .on controls execution within this module, .use controls whether or not PLDAPS executes this module at all!
        %   ------------------------
        
        %unlock the defaultParameters
        p.defaultParameters.setLock(false);
        % Create the new level
        p.defaultParameters.addLevels({newLvlStruct}, {sprintf('calibrationTrial%dParameters', p.defaultParameters.pldaps.iTrial)});
        % append this new level to the baseParamsLevels
        p.static.pldaps.baseParamsLevels = [p.static.pldaps.baseParamsLevels, length(p.defaultParameters.getAllLevels)];
        
        
        %re-lock the defaultParameters
        p.defaultParameters.setLock(true);
        
        % Programmatically return to pause state
        p.trial.pldaps.pause.type = 1;
        p.trial.flagNextTrial = 1;
        
        %         com.mathworks.mlservices.MLExecuteServices.consoleEval('dbcont');
        
    end %finishCalibration


%% initParams(p, sn)
% Initialize default module parameters
    function initParams(p, sn)
        % list of default parameters
        maxSamples = 500;
        
        def = struct(...
            'on', true,...
            'mode', 2,...   % limit type (0==pass/none, 1==square, 2==euclidean/circle)
            'isheld',0,...  % current state of fixation
            'targPos',[0 0 p.trial.display.viewdist]',... % xyz position
            'dotSz', 7,...   % fix dot size (pixels)
            'col',[0 0 0 1]',...    % fix dot color [R G B A]
            'dotType',2,...    % use basic PTB anti-aliased dots by default
            'fixLim', [2 2],...  % fixation window (deg)
            'cm0', [],...
            'maxSamples', maxSamples,...
            'fixations', nan(3, maxSamples) ...
            );
        
        p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);
        % create static dot buffer fields in case (only needed if linux & rendering with dotType >2 & <10
        p.static.(sn).dotBuffers = [];
        
    end % end initParams


%% drawTheFixation(p, sn)
    function drawTheFixation %(p, sn)
        % .texRectCtr is centered on screen .display.
        if p.trial.(sn).on
            %                     ctr = round(p.trial.display.ctr(1:2)') - [1, 0.5]; %!?? whats the deal with this offset correction??
            for i = p.trial.display.bufferIdx
                Screen('SelectStereoDrawBuffer',p.trial.display.ptr, i);
                Screen('DrawDots', p.trial.display.ptr, targPx, sz, p.trial.tracking.col, [], 2);   %p.trial.(sn).targPos(1:2, i+1)
            end
        end
    end %drawTheFixation


%% drawGLFixation(p, sn)
    function drawGLFixation%(p, sn)
        
        if p.trial.(sn).on
            % Render dot in 3D space
            p.static.(sn).dotBuffers = pldapsDrawDotsGL(...    (xyz, dotsz, dotcolor, center3D, dotType, glslshader)
                p.trial.(sn).targPos'...
                , p.trial.(sn).dotSz...
                , p.trial.(sn).col...
                , -p.trial.display.obsPos...
                , p.trial.(sn).dotType...
                , p.static.(sn).dotBuffers);
        end
    end %drawGLFixation



% end % end main function



% % % % % % % % %


%% Nested Functions
% % % % % % % % %


%% printDirections;
    function printDirections
        disp('Running Calibration Trial')
        fprintf('[f] \tLabel fixation\n[F] \tLabel fixation & advance to next target\n')
        fprintf('[e] \tErase last fixation\n[E] \tErase all fixations (i.e. restart calibration)\n')
        fprintf('[u] \tUpdate calibration transform\n[U]\tReset calibration to zero\n')
        
        % fprintf('s \tsave calibration to parameters\n')
        fprintf('[t] \tShow next target\n')
        fprintf('[p] \tExit calibration and return to pause state\n')
        fprintf('\n')
        fprintf('[1-9]\tPresent target at # grid location\n')
        fprintf('[0]\tHide targets\n')
        
    end

%% updateCalibTransform(p)
    function updateCalibTransform(p)
        
        
        % undo the existing calibration matrix
        n = p.static.tracking.thisFix;
        
        if n<5
            % initialize calibration fields if not enough data present
            if ~isfield(p.trial.tracking,'tform') || isempty(p.trial.tracking.tform)
                if isfield(p.trial.tracking, 'cm0') && ~isempty(p.trial.tracking.cm0)
                    % TODO:  bino compatible
                    p.trial.tracking.tform = projective2d(p.trial.tracking.cm0);
                else
                    p.trial.tracking.tform = projective2d;
                    p.trial.tracking.cm0 = p.trial.tracking.tform.T;
                end
                fprintf('~~~\tCalibration transform initialized\n')
            else
                warning('~!~\nInsufficient fixation samples for recalculating calibration matrix.\n');
            end
        else
            % Decompose raw tracking data and target positions from calibration data (p.static.tracking.fixations)
            xyRaw = imag(p.static.tracking.fixations(:, 1:n));  % only raw vals should be stored in fixations.
            targXY = real(p.static.tracking.fixations(:, 1:n));
            % Fit geometric transform
            p.trial.tracking.tform = fitgeotrans(xyRaw(1:2,:)', targXY(1:2,:)', 'projective'); % tform types: ['nonreflective', 'affine', 'projective', ...]
            p.trial.tracking.cm = p.trial.tracking.tform.T;
            fprintf('Tracking calibration updated:\n');
            fprintf('\t%#7.3f\t%#7.3f\t%#7.3f\n', p.trial.tracking.tform.T');    %p.static.tracking.calib.matrix.T);
            fprintf('\n');
            
        end
        
    end %updateCalibTransform


%% updateCalibPlot(p)
    function updateCalibPlot(p)
        n = 1:p.static.tracking.thisFix;
        % Initialize
        Hf = figure(p.condMatrix.baseIndex+1); clf %             figure(42); clf
        set(Hf, 'windowstyle','normal', 'toolbar','none', 'menubar','none', 'selectionHighlight','off', 'color',.5*[1 1 1], 'position',[1200,100,600,400]-80)
        set(Hf, 'Name', ['Calib:  ',p.trial.session.file], 'NumberTitle','off')
        
        sp = axes;  cla;% subplot(1,3,1:2);
        set(sp, 'plotboxaspectratio',[p.trial.display.ctr(1:2),1])
        hold on;   box off
        axis equal; hold on
        
        allTargs = p.trial.tracking.targets.xyPx - p.trial.display.ctr(1:2)';
        cols = hsv(size(allTargs,2));
        
        % plot targets
        plot( allTargs(1,:), -allTargs(2,:), 'd','color',.8*[1 1 1])
        
        % mark currently active target
        plot( allTargs(1,p.trial.tracking.targets.i), -allTargs(2,p.trial.tracking.targets.i), 'rx');%,'color',.4*[1 1 1]);
        
        
        axis(1.2*axis);
        
        if ~isempty(n)
            % plot fixations
            fixTargs = real(p.static.tracking.fixations(1:2,n))' - p.trial.display.ctr(1:2);
            fixVals  = imag(p.static.tracking.fixations(1:2,n))';% - p.trial.display.ctr(1:2);
            
            [uTargs, ~, fix2targ] = unique(fixTargs, 'rows');
            [~, fixCols] = ismember(uTargs, allTargs','rows');
            fixCols = fixCols(fix2targ); % expand for each target repeat
            
            plot( uTargs(:,1), -uTargs(:,2), 'kd')
            % plot raw data
            scatter(fixVals(:,1)- p.trial.display.ctr(1), -(fixVals(:,2)- p.trial.display.ctr(2)), [], cols(fixCols,:), 'markerfacecolor','none','markeredgealpha',.3);    %cols(fix2targ,:)
            
            if isfield(p.trial.tracking, 'tform')
                % plot calibrated data
                fixCaled = transformPointsForward(p.trial.tracking.tform, fixVals)- p.trial.display.ctr(1:2);
                scatter(fixCaled(:,1), -fixCaled(:,2), [], cols(fixCols,:), 'filled', 'markeredgecolor','none','markerfacealpha',.3);    %cols(fix2targ,:)
            end
        end
        
        drawnow
    end


%% updateTarget(p)
    function updateTarget(p)
        
        if isfield(p.trial.tracking, 'nextTarg')
            i = p.trial.tracking.nextTarg;
        else
            i = randsample(1:p.trial.tracking.targets.nTargets, 1); % first target location
        end
        
        p.trial.tracking.targets.i = i;
        ii = find(p.trial.tracking.targets.randOrd==i);
        p.trial.tracking.nextTarg = p.trial.tracking.targets.randOrd(mod(ii, p.trial.tracking.targets.nTargets)+1);
        % p.trial.tracking.nextTarg = randsample(ii(ii~=i), 1);
%         p.trial.tracking.col(4) = 1;
        
        updateCalibPlot(p);
        
    end



%% logFixation(p)
    function logFixation(p)
        if ~p.trial.tracking.col(4)
            fprintf(2, '~!~\tNo fixation logged; targets currently HIDDEN from subject\n~!~\t-- Press [zero] to toggle visibility\n');
        
        else
            p.static.tracking.thisFix = p.static.tracking.thisFix + 1;
            % complex XZY values with: target positions in the real component, eye positions in the imaginary component
            p.static.tracking.fixations(:, p.static.tracking.thisFix) = [p.trial.tracking.targets.xyPx(:,p.trial.tracking.targets.i); p.trial.display.viewdist] + ...
                ...[p.trial.eyeX; p.trial.eyeY; p.trial.display.viewdist].*1i; %,  [p.trial.(sn).targets(p.trial.(sn).iTarget).xPx(fixatedTarget); p.trial.(sn).targets(p.trial.(sn).iTarget).yPx(fixatedTarget); p.trial.eyeX; p.trial.eyeY];
                [p.trial.tracking.posRaw; p.trial.display.viewdist].*1i;
            
            % give reward
            pds.behavior.reward.give(p);
            fprintf('.')
        end
    end

end % end main function


% % % % % % % % %
% % % % % % % % %
%% Sub Functions
% % % % % % % % %
% % % % % % % % %


%% setupTargets(p)
function targets = setupTargets(p)
% sample target positions
targets = struct();

halfWidth = 10;
% basic 9-point target grid (in degrees)
[xx, yy] = meshgrid(-halfWidth:halfWidth:halfWidth);
xx = xx(:); yy = yy(:);
if 1
    % add inner target points
    [x2, y2] = meshgrid( halfWidth/2 * [-1 1]);
    xx = [xx; x2(:)];
    yy = [yy; y2(:)];
end
zz = zeros(size(xx));

targets.targPos = [xx(:) yy(:), zz(:)]' .* p.trial.tracking.calib.targetScale;
% Target position in WORLD coordinates [CM]
% add targPos to the viewDist baseline for final depth in world coordinates
targets.targPos(3,:) = targets.targPos(3,:) + p.trial.display.viewdist;
% convert XY degrees to CM, given the distance in depth CM
% targets.targPos(1:2,:) = pds.deg2world(targets.targPos(1:2,:)', targets.targPos(3,:), 0); % p.deg2world(p, p.trial.(sn).stimPosDeg(1:2)');      %
targets.xyPx = pds.deg2px(targets.targPos(1:2,:), targets.targPos(3,:), p.trial.display.w2px,  0) + p.trial.display.ctr(1:2)';

targets.timeUpdated = GetSecs;
targets.nTargets = size(targets.targPos,2);
targets.randOrd = randperm(targets.nTargets);
% targets.numShown = randi(targets.nTargets);
% targets.targsShown = randsample(targets.nTargets, targets.numShown, false);

targets.sizePhase = rand * 2 * pi;
targets.sizeFreq  = rand * 10;

end


