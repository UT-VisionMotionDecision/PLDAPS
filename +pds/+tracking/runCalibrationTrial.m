function p = runCalibrationTrial(p, state, sn)
% function p = pds.tracking.runCalibrationTrial(p, state, sn)
% 
% Activate calibration trial from pause state by calling:
%       pds.tracking.runCalibrationTrial(p)  % i.e. nargin==1
% 
% See also:  pds.tracking
% 
% 2020-01-xx  TBC  Wrote it.
% 


if nargin<3 || isempty(sn)
    sn = 'tracking';
end

% populate local workspace variables
srcIdx = p.trial.(sn).srcIdx; % NOTE: This should/must be a one-based, not zero-based index!

if nargin<2 || isempty(state)
    % special case to initiate calibration trial(s) from pause state
    %if isfield(p.trial.(sn), 'on') && ~p.trial.(sn).on
    if ~p.trial.(sn).on
        % set tracking calibration module on, & disable all modules with order > tracking module
        startCalibration;%(p, sn);
        return
        
    else
        % this should not occur...
        fprintf(2,'~!~\tStrange start to tracking calibration...I cannot.\n')
        fprintf('~!~\t.%s.on should only be toggled by self when calling  pds.tracking.runCalibrationTrial(p)  %% i.e. nargin==1\n', sn, mfilename)
        fprintf('~!~\tToggle .%s.use to enable/disable tracking module (but o.t.f. switching will prob crash)\n', sn)
        p.trial.(sn).on = false;
        return
    end
% %     elseif isfield(p.trial.(sn), 'on') && p.trial.(sn).on
% %     NOPE:  This is now run automatically at end of calibration trial
% %         % turn tracking calibration module off, & reenable module state prior to calibration phase
% %         finishCalibration;%(p, sn);
% %         return
% % 
%     else
%         % get list of currently active modules
%         [moduleNames] = getModules(p, 1);
%         p.trial.(sn).tmp.initialActiveModules = moduleNames;
%         
%     end
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
        % TRIAL STATES
    case p.trial.pldaps.trialStates.trialItiDraw
        % drawTheFixation(p, sn);  % maintain fixation during iti
        
        
    case p.trial.pldaps.trialStates.trialPrepare
                
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
        % --- Trial Setup: pre-allocate important variables for storage and
        if p.trial.(sn).on
            % identify tracking source
            src = p.trial.tracking.source;
            
            if ~isfield(p.trial.tracking, 't0') || isempty(p.trial.tracking.t0)
                p.trial.tracking.t0 = p.trial.tracking.tform;
            end
            
            % targX, targY, eyeX, eyeY, distance
            % targetXZY = real(p.trial.(sn).fixations);
            % eyeXYZ = imag(p.trial.(sn).fixations);
            
            % Initialize fixaitons (or recall from p.static) for this trial
            if ~isfield(p.static.tracking,'fixations') || isempty(p.static.tracking.fixations)
                p.trial.tracking.fixations = nan( [3, p.trial.tracking.maxSamples, max(srcIdx)]);
                p.trial.tracking.thisFix = 0;
            else
                p.trial.tracking.fixations = p.static.tracking.fixations;
                p.trial.tracking.thisFix = p.static.tracking.thisFix;
            end
            updateCalibTransform(p)
            
            p.trial.tracking.targets = setupTargets(p);
            updateTarget(p);
            
%             if ~isfield(p.trial.tracking, 'cm')
%                 p.trial.tracking.cm = p.trial.tracking.cm0;
%             end
            
            updateCalibPlot(p);
            
            printDirections;
        end
        
        
        %--------------------------------------------------------------------------
        % --- Manage stimulus before frame draw
    case p.trial.pldaps.trialStates.framePrepareDrawing %frameUpdate
        if p.trial.(sn).on
                        
            %% Keyboard functions
            if any(p.trial.keyboard.firstPressQ)
                
                if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.fKey)
                    % [f,F] key - log fixation
                    logFixation(p);
                    if p.trial.keyboard.modKeys.shift
                        % [F] ...and move to next random target
%                         p.trial.tracking.nextTarg = p.trial.tracking.targets.randOrd(mod(p.trial.tracking.thisFix, p.trial.tracking.targets.nTargets)+1);
                        updateTarget(p);

                        % give reward
                        pds.behavior.reward.give(p, p.trial.tracking.fixReward); % default small amount for calibration
                    end
                    
                    
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.vKey)
                    % [v] key - Validate fixation
                    %           Reward & move to next random point, but don't add point to calibration data
                    %           TODO: extend this to do real a real validation & report accuracy
                    updateTarget(p);
                    % give reward
                    pds.behavior.reward.give(p, p.trial.tracking.fixReward); % default small amount for calibration

                    
                elseif p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.spaceKey)
                    % [SPACEBAR] - log fixation & move to next random target (...same as shift-f [F])
                    logFixation(p);
                    updateTarget(p);
                    %updateCalibPlot(p);
                    
                    % give reward
                    pds.behavior.reward.give(p, p.trial.tracking.fixReward);
                    
                    
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.uKey)
                    % [u, U] key - update calibration matrix
                    updateCalibTransform(p);
                    %updateCalibPlot(p);

                    
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.tKey)
                    % [T] key - update targets (i.e. change target w/o logging fixation)
                    p.trial.tracking.col(4) = 1;
                    updateTarget(p);
                    

                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.zerKey) || p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.KPzerKey)
                    % [ZERO] key - blank targets
                    if ~p.trial.tracking.col(4)
                        p.trial.tracking.col(4) = 1;
                    else
                        p.trial.tracking.col(4) = 0;
                    end
                    
                    
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.eKey)
                    % [E] key - remove last fixation
                    % [SHIFT-E] remove ALL fixations!
                    if p.trial.keyboard.modKeys.shift
                        resetCalibration(p);
                        % TODO:  ideally use a modKey to only erase calibration points for current viewdist
                    else
                        p.trial.tracking.thisFix = p.trial.tracking.thisFix - 1;
                    end
                    
                    
                elseif  ~isempty(p.trial.keyboard.numKeys.pressed)   %(p.trial.keyboard.codes.oneKey)
                    % [1-9] Jump to specified target location
                    if p.trial.keyboard.numKeys.pressed(end)>0
                        p.trial.tracking.nextTarg = p.trial.keyboard.numKeys.pressed(end);
                        % disp(p.trial.tracking.nextTarg)
                        updateTarget(p)
                    end
                    
                end
                % update plot on any user interaction
                updateCalibPlot(p);
            end
        end
        
        
        %--------------------------------------------------------------------------
        % --- Draw the frame
    case p.trial.pldaps.trialStates.frameDraw
        if p.trial.(sn).on
            
            % Pulsating target dot
            sz = p.trial.tracking.dotSz + (p.trial.tracking.dotSz/3 * sin(p.trial.ttime*10));
                        
            % Screen('DrawDots', p.trial.display.ptr, targPx, sz, p.trial.tracking.col, [], 2);
%             if ~p.trial.display.useGL
                % Show target on subject screen
                targPx = p.trial.tracking.targets.xyPx(:,p.trial.tracking.targets.i);
                % nested fxns have access to this workspace...no inputs needed
                drawTheFixation; %(p, sn);
%             end
            
            if p.trial.pldaps.draw.eyepos.use && p.trial.display.useOverlay
                % show past & current eye position on screen
                for i = srcIdx
                    if p.trial.tracking.thisFix > 0
                        % fixations in this calibration
                        pastFixPx = transformPointsInverse(p.trial.tracking.tform(i), imag(p.trial.tracking.fixations(1:2, 1:p.trial.tracking.thisFix, i))')';
                        Screen('DrawDots', p.trial.display.overlayptr, pastFixPx(1:2,:), 5, p.trial.display.clut.red, [], 0);    %[0 1 0 .7], [], 0);
                    end
                    
                    % eye position with current transform
                    newEye = transformPointsInverse(p.trial.tracking.tform(i), p.trial.tracking.posRaw(:,min([i,end]))')'; %p.trial.tracking.cm * p.trial.tracking.eyeRaw;
%                     for i = 1:size(newEye,2)
                        % Screen('DrawDots', p.trial.display.overlayptr, newEye(1:2), 5, [0 1 0 1]', [], 0);
                        % this eye color is zero-based (to match PTB stereoBuffer indexing...for better or worse)
                        Screen('DrawDots', p.trial.display.overlayptr, newEye(1:2), 5, p.trial.display.clut.(['eye',num2str(i-1)]), [], 0);
%                     end
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
            % carry over calibration data in p.static
            p.static.tracking.fixations = p.trial.tracking.fixations(:, 1:p.trial.tracking.thisFix, :);
            p.static.tracking.thisFix = p.trial.tracking.thisFix;
            
            updateCalibTransform(p);
            updateCalibPlot(p);
            
            p.static.tracking.tform = p.trial.tracking.tform;
            % pds.tracking.updateMatrix(p);
            
            finishCalibration;
        end
        
end %state switch block


%% Nested functions
% have access to all local variables (no need to pass inputs/outputs unless special case)

%% startCalibration;
    function startCalibration
        % get list of currently active modules
        [moduleNames] = getModules(p, 1);
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
        
        
        %!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!
        % (....wtf!?? So archaic& cryptic!  MUST GET AWAY from this params class business!!
        %!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!%!
        
        
        
        % Poll current pldaps 'levels' state (...goofy params class stuff)
        % Create new 'level', that re-enables modules that were active when this calibration started
        newLvlStruct = struct;
        fn = p.trial.(sn).tmp.initialActiveModules;
        for i = 1:length(fn)
            newLvlStruct.(fn{i}).use = true;
        end
        % turn this module off in the new level
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
        
        % Flag return to pause state
        p.trial.pldaps.pause.type = 1;
        p.trial.flagNextTrial = 1;
                
    end %finishCalibration


%% initParams(p, sn)
% Initialize default module parameters
    function initParams(p, sn)
        % list of default parameters
        maxSamples = 50;
        
        def = struct(...
            'on', false,... % should only be switched on/off by calling pds.tracking.runCalibrationTrial(p)  % i.e. nargin==1
            'mode', 2,...   % limit type (0==pass/none, 1==square, 2==euclidean/circle)
            'isheld',0,...  % current state of fixation
            'targPos',[0 0 p.trial.display.viewdist]',... % xyz position
            'gridSz', [20, 16],... target grid size [x, y], in deg 
            'dotSz', 5,...   % fix dot size (pixels)
            'col',[0 0 0 0]',...    % fix dot color [R G B A];  initially blank default, press zero to reveal/begin
            'dotType',2,...    % use basic PTB anti-aliased dots by default
            'fixLim', [2 2],...  % fixation window (deg)
            'fixReward', 0.1,... % small default reward volume for calibration
            'maxSamples', maxSamples,... % is this necessary?
            'fixations', [] ... %nan(3, maxSamples) ...
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
        fprintf('[f] \tLabel fixation (no reward)\n[F] \tLabel fixation & advance to next target (w/ reward)\n')
        fprintf('[e] \tErase last fixation\n[E] \tErase all fixations (i.e. restart calibration)\n')
        fprintf('[u] \tUpdate calibration transform\n[U]\tReset calibration to zero\n')
        
        % fprintf('s \tsave calibration to parameters\n')
        fprintf('[t] \tShow next target\n')
        fprintf('[p] \tExit calibration and return to pause state\n')
        fprintf('\n')
        fprintf('[1-9]\tPresent target at # grid location\n')
        fprintf('[0]\tHide/Show targets\n')
        
    end

%% updateCalibTransform(p)
    function updateCalibTransform(p)
        
        n = p.trial.tracking.thisFix;
        
        if n>=10
            %% Fit calibration to fixation data
            for i = srcIdx
                % Decompose raw tracking data and target positions from calibration data (p.trial.tracking.fixations)
                xyRaw = imag(p.trial.tracking.fixations(:, 1:n, i));  % only raw vals should be stored in fixations.
                targXY = real(p.trial.tracking.fixations(:, 1:n, i));
                
                % Fit geometric transform
                % - tform types: ['nonreflective', 'affine', 'projective', 'polynomial']  ...make this selectable based on source field
                % - eye/target data are input conceptually backwards, but polynomial tform methods are limited to inverse transform
                p.trial.tracking.tform(i) = fitgeotrans(targXY(1:2,:)', xyRaw(1:2,:)', 'polynomial',2);
                
                fprintf('Tracking calibration [%d] updated:\n',i);
                disp(p.trial.tracking.tform(i));
            end
            fprintf('\n');
            
        else
            %% initialize calibration transform
            %   fields if empty or not enough data present
            if ~isfield(p.trial.tracking,'tform') || isempty(p.trial.tracking.tform)
                % NOTE: All indexed tform methods must match...therefore, initialization must be consistent
                for i = 1:srcIdx
                    % [PROJECTIVE] or [AFFINE] are ok mixed/unitialized
                    %   p.trial.tracking.tform(i) = projective2d;
                    
                    % [POLYNOMIAL] requires manual setup
                    %   - all lesser indices must exist, else poly tform object construction fails
                    %   - ?? is there no clean/agnostic way to initialize a polynomial transform?? (e.g. t = affine2d;)
                    % 2nd degree
                    p.trial.tracking.tform(i) = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0], [0 0 1 0 0 0]);
                    %     % 3rd degree
                    %     p.trial.tracking.tform(i) = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0 0 0 0 0], [0 0 1 0 0 0 0 0 0 0]);
                    
                    fprintf('~~~\tCalibration transform [%d] initialized\n', i)
                end
            else
                fprintf(2, '~!~\tInsufficient fixation samples for tracking calibration.\n');
            end
        end
        
    end %updateCalibTransform


%% updateCalibPlot(p)
    function updateCalibPlot(p)
        n = 1:p.trial.tracking.thisFix;
        
        % Initialize
        Hf = figure(p.condMatrix.baseIndex+1); clf %             figure(42); clf
        set(Hf, 'windowstyle','normal', 'toolbar','none', 'menubar','none', 'selectionHighlight','off', 'color',.5*[1 1 1], 'position',[1200,100,600,400]-80)
        set(Hf, 'Name', ['Calib:  ',p.trial.session.file], 'NumberTitle','off')
        
        sp = axes;  cla;
        set(sp, 'plotboxaspectratio',[p.trial.display.ctr(1:2),1])
        hold on;   box off
        axis equal; hold on
        
        allTargs = p.trial.tracking.targets.xyPx - p.trial.display.ctr(1:2)';
        cols = hsv(size(allTargs,2));
        
        % plot targets
        plot( allTargs(1,:), -allTargs(2,:), 'd','color',.8*[1 1 1])
        
        % mark currently active target
        plot( allTargs(1,p.trial.tracking.targets.i), -allTargs(2,p.trial.tracking.targets.i), 'ro', 'markersize',10, 'linewidth',1.2);
        
        % Report target visibility in gui fig
        if p.trial.tracking.col(4)
            title('[- Target visible -]', 'fontsize',10, 'fontweight','bold');
        else
            title('[- Target hidden -]', 'fontsize',10, 'fontweight','normal'); %, 'color',[1,.1,.1]);
        end
        
        axis(1.2*axis);
        
        if ~isempty(n)
            % plot fixations
            for i = srcIdx
                fixTargs = real(p.trial.tracking.fixations(1:2, n, i))' - p.trial.display.ctr(1:2);
                fixVals  = imag(p.trial.tracking.fixations(1:2, n, i))';    % - p.trial.display.ctr(1:2);
                
                if ~all(isnan(fixVals(:)))
                    % only plot if fixation data present
                    [uTargs, ~, fix2targ] = unique(fixTargs, 'rows');
                    [~, fixCols] = ismember(uTargs, allTargs','rows');
                    
                    if any(fixCols==0)
                        % mismatch between target positions and recorded fixations
                        % Resetting calibration to prevent crash
                        resetCalibration(p)
                    else
                        fixCols = fixCols(fix2targ); % expand for each target repeat
                        
                        plot( uTargs(:,1), -uTargs(:,2), 'kd')
                        % plot raw data
                        scatter(fixVals(:,1)- p.trial.display.ctr(1), -(fixVals(:,2)- p.trial.display.ctr(2)), [], cols(fixCols,:), 'markerfacecolor','none','markeredgealpha',.3);
                        
                        if isfield(p.trial.tracking, 'tform')
                            % plot calibrated data
                            fixCaled = transformPointsInverse(p.trial.tracking.tform(i), fixVals)- p.trial.display.ctr(1:2);
                            scatter(fixCaled(:,1), -fixCaled(:,2), [], cols(fixCols,:), 'filled', 'markeredgecolor','none','markerfacealpha',.3);
                        end
                    end
                end
            end
        end
        
        drawnow
    end


%% resetCalibration(p)
    function resetCalibration(p)
        % packaged for easy call/editing
        p.trial.tracking.fixations = nan(3, p.trial.tracking.maxSamples, max(srcIdx));
        p.trial.tracking.thisFix = 0;
        p.trial.tracking.targets = setupTargets(p);
        updateTarget(p);
        updateCalibPlot(p);
        
    end %resetCalibration


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
        
        updateCalibPlot(p);
        
    end



%% logFixation(p)
    function logFixation(p)
        if ~p.trial.tracking.col(4)
            fprintf(2, '~!~\tNo fixation logged; targets currently HIDDEN from subject\n~!~\t-- Press [zero] to toggle visibility\n');
        
        else
            p.trial.tracking.thisFix = p.trial.tracking.thisFix + 1;
            for i = srcIdx
                % Keep target & eye values together using complex numbers:  target == real(xyz), eye == imag(xyz)
                p.trial.tracking.fixations(:, p.trial.tracking.thisFix, i) = ...
                    [p.trial.tracking.targets.xyPx(:,p.trial.tracking.targets.i); p.trial.display.viewdist] + ... % Target position in real component
                    1i.*[p.trial.tracking.posRaw(:,min([i,end])); p.trial.display.viewdist]; % Measured eye position in imaginary component
                
            end
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
% Create target positions struct
targets = struct();

halfWidth_x = p.trial.tracking.gridSz(1)/2;
halfWidth_y = p.trial.tracking.gridSz(end)/2;

% basic 9-point target grid (in degrees)
xx = -halfWidth_x:halfWidth_x:halfWidth_x;
yy = -halfWidth_y:halfWidth_y:halfWidth_y;
[xx, yy] = meshgrid(xx, yy);
% arrange to match numpad
xy = sortrows([xx(:),yy(:)], [-2,1]);
if 1
    % add inner target points
    [x2, y2] = meshgrid( halfWidth_x/2*[-1 1], halfWidth_y/2*[1 -1]);
    xy = [xy; [x2(:), y2(:)]];
end
zz = zeros(size(xy,1),1);

targets.targPos = [xy, zz(:)]' .* p.trial.tracking.gridScale;
% Target position in WORLD coordinates [CM]
% add targPos to the viewDist baseline for final depth in world coordinates
targets.targPos(3,:) = targets.targPos(3,:) + p.trial.display.viewdist;
% % Ideally draw in 3D:
%   % convert XY degrees to CM, given the distance in depth CM
%   targets.targPos(1:2,:) = pds.deg2world(targets.targPos(1:2,:)', targets.targPos(3,:), 0); % p.deg2world(p, p.trial.(sn).stimPosDeg(1:2)');      %
% % ...use Pixels in a pinch
targets.xyPx = pds.deg2px(targets.targPos(1:2,:), targets.targPos(3,:), p.trial.display.w2px,  0) + p.trial.display.ctr(1:2)';

targets.timeUpdated = GetSecs;
targets.nTargets = size(targets.targPos,2);
targets.randOrd = randperm(targets.nTargets);


end


