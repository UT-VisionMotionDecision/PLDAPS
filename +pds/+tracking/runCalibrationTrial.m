function p = runCalibrationTrial(p, state, sn)
% function p = pds.tracking.runCalibrationTrial(p, state, sn)
% 
% Activate calibration trial from pause state by calling:
%       pds.tracking.runCalibrationTrial(p)  % i.e. nargin==1
% 
% - p.static.tracking object is created by pds.tracking.setup & pds.tracking.postOpenScreen,
%   which are executed w/in pldapsDefaultTrial.m
% 
% See also:  pds.tracking
% 
% 2020-01-xx  TBC  Wrote it.
% 2020-09-xx  TBC  Updating for p.static OOP components (important/ongoing PLDAPS pivot & necessary for viewdist coordination)
% 

% TODO:  Initialization is wiping out existing .fixations (...but only on first run of loaded calibration)
%        - Need to update primary calibration data storage to use tracking object (limiting p.trial back-and-forth)
%   Consistency issues:
%       - rendering params (.tracking.col) are still in p.trial  (this sort of makes sense, but could become confusing)
%       - .rawPos is placed in p.trial.tracking by updateFxn
%       -- (orphaned from object & calibration, but appropriate for trial data (esp if moved to record on every frame)
% 

if nargin<3 || isempty(sn)
    sn = 'tracking';
end
% NOTE:  .(sn) not used during dev., most instances hardcoded with .tracking for now
% ...can update for flexibility later


% Populate local workspace variables
srcIdx = p.static.tracking.srcIdx; % p.trial.(sn).srcIdx; % NOTE: This should/must be a one-based, not zero-based index!
persistent Hf Ax    % [Hf] & [Ax] are local persistent variable to figure & axes handles


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
        fprintf('~!~\t.%s.on should only be toggled by self when calling\n\t>> pds.tracking.runCalibrationTrial(p); \n%% i.e. nargin==1\n', sn, mfilename)
        fprintf('~!~\tToggle .%s.use to enable/disable tracking module (but support for o.t.f. switching is unlikely)\n', sn)
        p.trial.(sn).on = false;
        return
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
        % setup run params in PLDAPS struct
        initParams(p, sn);
        
        %--------------------------------------------------------------------------
        % TRIAL STATES        
    case p.trial.pldaps.trialStates.trialSetup
        % --- Trial Setup: pre-allocate important variables for storage and
        if p.trial.(sn).on
            % identify tracking source
            src = p.static.tracking.source;
            
            if ~isfield(p.trial.tracking, 't0') || isempty(p.trial.tracking.t0)
                p.trial.tracking.t0 = p.static.tracking.tform;
            end
            
            % Don't double-draw eyepos (this will revert itself)
            p.trial.pldaps.draw.eyepos.use = false;
            
            % targX, targY, eyeX, eyeY, distance
            % targetXZY = real(p.trial.(sn).fixations);
            % eyeXYZ = imag(p.trial.(sn).fixations);
            
            % Initialize fixaitons (or recall from p.static) for this trial
            updateCalibTransform(p)
            
            % p.static.tracking.targets = setupTargets(p);
            p.static.tracking.setupTargets();
            updateTarget(p);
                        
            updateCalibPlot(p);
            
            printDirections;
        end

        
    % case p.trial.pldaps.trialStates.trialPrepare
                
        
        %--------------------------------------------------------------------------
        % --- Manage stimulus before frame draw
    case p.trial.pldaps.trialStates.framePrepareDrawing
        if p.trial.(sn).on
                        
            %% Keyboard functions
            if any(p.trial.keyboard.firstPressQ)
                % Check keyboard for defined actions (nested function)
                doKeyboardChecks;
            end
            
        end
        
        
        %--------------------------------------------------------------------------
        % --- Draw the frame
    case p.trial.pldaps.trialStates.frameDraw
        
        if p.trial.(sn).on
            % Pulsating target dot
            sz = p.trial.tracking.dotSz + (p.trial.tracking.dotSz/3 * sin(p.trial.ttime*10));
            
            % Show target on subject screen
            targPx = p.static.tracking.targets.xyPx(:,p.static.tracking.targets.i);
            % nested fxns have access to this workspace...no inputs needed
            drawTheFixation; %(p, sn);
            
            if p.trial.display.useOverlay
                % find all recorded fixations that match current viewdist
                n = imag(p.static.tracking.fixations(3,:,srcIdx(1))) == p.static.display.viewdist;

                % Show past & current eye position on screen
                for i = srcIdx
                    if p.static.tracking.thisFix > 0
                        % fixations in this calibration
                        pastFixPx = (1:length(n)<=p.static.tracking.thisFix & n); % use variable to subselect indices of current data first...
                        if any(pastFixPx)
                            pastFixPx = transformPointsInverse(p.static.tracking.tform(i), imag(p.static.tracking.fixations(1:2, pastFixPx, i))')';
                            Screen('DrawDots', p.trial.display.overlayptr, pastFixPx(1:2,:), 5, p.trial.display.clut.red, [], 0);    %[0 1 0 .7], [], 0);
                        end
                    end
                    
                    % Draw current eye position with calibration applied
                    newEye = transformPointsInverse(p.static.tracking.tform(i), p.trial.tracking.posRaw(:,min([i,end]))')';
                    % 'this' eye color is zero-based (to match PTB stereoBuffer value...for better or worse)
                    Screen('DrawDots', p.trial.display.overlayptr, newEye(1:2), 10, p.trial.display.clut.(['eye',num2str(i-1)]), [], 0);
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
            % final updates
            updateCalibTransform(p);
            updateCalibPlot(p);
            
            % place copy of tform & fixations in p.trial struct of this calibration trial for record keeping/posterity
            p.trial.tracking.fixations = p.static.tracking.fixations;
            p.trial.tracking.tform = p.static.tracking.tform;
            
            % save calibration to file
            calOutput = p.static.tracking;
            save(p.static.tracking.calPath.saved, 'calOutput', '-v7')
            fprintf('Calibration saved as:\n\t%s\n', p.static.tracking.calPath.saved);
            
            finishCalibration;
            fprintLineBreak('='); %done
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
        
        % Initialize GUI figure
        getCalibFig;
        
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
        minSamples = p.static.tracking.minSamples;
        
        def = struct(...
            'on', false,... % should only be switched on/off by calling pds.tracking.runCalibrationTrial(p)  % i.e. nargin==1
            'mode', 2,...   % limit type (0==pass/none, 1==square, 2==euclidean/circle)
            'isheld',0,...  % current state of fixation
            'targPos',[0 0 p.trial.display.viewdist]',... % xyz position
            'gridSz', [20, 16],... target grid size [x, y], in deg 
            'dotSz', 10,...   % fix dot size (pixels)
            'col',[0 0 0 0]',...    % fix dot color [R G B A];  initially blank default, press zero to reveal/begin
            'dotType',2,...    % use basic PTB anti-aliased dots by default
            'fixLim', [2 2],...  % fixation window (deg)
            'fixReward', 0.1,... % small default reward volume for calibration
            'minSamples', minSamples,... % is this necessary?
            'fixations', [] ... %nan(3, minSamples) ...
            );
        
        p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);
        % create static dot buffer fields in case (only needed if linux & rendering with dotType >2 & <10
        p.static.(sn).dotBuffers = [];
        
    end % end initParams


%% doKeyboardChecks
    function doKeyboardChecks
        if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.fKey)
            % [f,F] key - log fixation
            logFixation(p);
            if p.trial.keyboard.modKeys.shift
                % [F] ...and give reward
                pds.behavior.reward.give(p, p.trial.tracking.fixReward); % default small amount for calibration
            end
            
            
        elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.vKey)
            % [v] key - Validate fixation
            %           Reward & move to next random point, but don't add point to calibration data
            %           TODO: extend this to do a real validation & report accuracy
            updateTarget(p);
            % give reward
            pds.behavior.reward.give(p, p.trial.tracking.fixReward); % default small amount for calibration
            
            
        elseif p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.spaceKey)
            % [SPACEBAR] - log fixation & move to next random target
            logFixation(p);
            updateTarget(p);
            
            % give reward
            pds.behavior.reward.give(p, p.trial.tracking.fixReward);
            
            
        elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.uKey)
            % [u, U] key - update calibration matrix
            fprintf('\n');
            updateCalibTransform(p);
            
            
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
                p.static.tracking.thisFix = p.static.tracking.thisFix - 1;
                p.static.tracking.thisFix(p.static.tracking.thisFix<0) = 0; % bottom out index to prevent error
            end
            
            
        elseif  ~isempty(p.trial.keyboard.numKeys.pressed)   %(p.trial.keyboard.codes.oneKey)
            % [1-9] Jump to specified target location
            if p.trial.keyboard.numKeys.pressed(end)>0
                p.static.tracking.nextTarg = p.trial.keyboard.numKeys.pressed(end);
                % disp(p.trial.tracking.nextTarg)
                updateTarget(p)
            end
        else
            % did nothing, skip over plot update & return
            return
        end
        
        % update plot on any user interaction
        updateCalibPlot(p);
        
    end %end keyboardChecks



%% drawTheFixation(p, sn)
    function drawTheFixation %(p, sn)
        if p.trial.(sn).on
            for i = p.static.display.bufferIdx
                Screen('SelectStereoDrawBuffer',p.static.display.ptr, i);
                Screen('DrawDots', p.static.display.ptr, targPx, sz, p.trial.tracking.col, [], 2);   %p.trial.(sn).targPos(1:2, i+1)
            end
        end
    end %drawTheFixation


% % % %% drawGLFixation(p, sn)
% % %     function drawGLFixation%(p, sn)
% % %
% % %         if p.trial.(sn).on
% % %             % Render dot in 3D space
% % %             p.static.(sn).dotBuffers = pldapsDrawDotsGL(...    (xyz, dotsz, dotcolor, center3D, dotType, glslshader)
% % %                 p.trial.(sn).targPos'...
% % %                 , p.trial.(sn).dotSz...
% % %                 , p.trial.(sn).col...
% % %                 , -p.trial.display.obsPos...
% % %                 , p.trial.(sn).dotType...
% % %                 , p.static.(sn).dotBuffers);
% % %         end
% % %     end %drawGLFixation



%% printDirections
    function printDirections
        
        fprintLineBreak('=')
        disp('Tracking Calibration Keys:')
        fprintLineBreak('-')
        keys = ["[spacebar]", "Record fixation, give reward, advance to next target";...
                "[f]", "Record fixation  (NO reward, NO advance)";...
                "[F]", "Record fixation, give reward  (NO advance)";...
                ".", "...........................";...
                "[e]", "Erase last fixation";...
                "[E]", "Erase ALL fixations (i.e. restart calibration)";...
                "[u]", "Update calibration transform";...
                "[U]", "Reset calibration to zero";...
                ".", "...........................";...
                "[t]", "Show next target (unhide, if hidden)";...
                "[0]", "Hide/Show targets";...
                "[1-9]", "Present target at # grid location";...
                ".", "...........................";...
                "[p]", "Exit calibration, save to file, & return to pause state"];
        keys(:,1) = pad(keys(:,1),'.');
        fprintf('%s.... %s\n',keys');
        fprintLineBreak('=')
        
    end %printDirections


%% updateCalibTransform(p)
    function updateCalibTransform(p)
        
        % find all recorded fixations that match current viewdist
        n = imag(p.static.tracking.fixations(3,:,srcIdx(1))) == p.static.display.viewdist;
                
        if sum(n)>=10 % minimum number of data points to perform fit
            %% Fit calibration to fixation data
            for i = srcIdx
                % Decompose raw tracking data and target positions from calibration data (p.trial.tracking.fixations)
                xyRaw = imag(p.static.tracking.fixations(:, n, i));  % only raw vals should be stored in fixations.
                targXY = real(p.static.tracking.fixations(:, n, i));
                
                % Fit geometric transform
                % - tform types: ['nonreflective', 'affine', 'projective', 'polynomial']  ...make this selectable based on source field
                % - eye/target data are input conceptually backwards, but polynomial tform methods are limited to inverse transform
                p.static.tracking.tform(i) = fitgeotrans(targXY(1:2,:)', xyRaw(1:2,:)', 'polynomial',3);
                
                fprintf('Tracking calibration [%d] updated for viewdist %scm\n', i, num2str(p.static.display.viewdist));
                
                % group all of same distance measurements together (makes adding/removing points otf more feasible)
                p.static.tracking.fixations(:,:,i) = [p.static.tracking.fixations(:, ~n, i), p.static.tracking.fixations(:, n, i)];
                % update index of current sample [.thisFix] to reordered fixations
                p.static.tracking.thisFix = size(p.static.tracking.fixations,2);
                
            end
            fprintf('\n');
            
        else
            %% initialize calibration transform
            %   fields if empty or not enough data present
            if ~isfield(p.static.tracking,'tform') || isempty(p.static.tracking.tform)
                % NOTE: All indexed tform methods must match...therefore, initialization must be consistent
                % !~TODO: This needs fix to prevent class consistency error (what is better/global aproach for this???)
                for i = 1:srcIdx
                    % [PROJECTIVE] or [AFFINE] are ok mixed/unitialized
                    %   p.trial.tracking.tform(i) = projective2d;
                    
                    % [POLYNOMIAL] requires manual setup
                    %   - all lesser indices must exist, else poly tform object construction fails
                    %   - ?? is there no clean/agnostic way to initialize a polynomial transform?? (e.g. t = affine2d;)
                    % % 2nd degree (...doesn't quite capture periphery well)
                    %  p.trial.tracking.tform(i) = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0], [0 0 1 0 0 0]);
                    % 3rd degree
                    p.static.tracking.tform(i) = images.geotrans.PolynomialTransformation2D([0 1 0 0 0 0 0 0 0 0], [0 0 1 0 0 0 0 0 0 0]);
                    
                    fprintf('~~~\tCalibration transform [%d] initialized\n', i)
                end
            else
                fprintf(2, '~!~\tInsufficient fixation samples for tracking calibration.\n');
            end
        end
        
    end %updateCalibTransform


%% getCalibFig
    function getCalibFig
        % - [Hf] & [Ax] are local persistent variable to figure & axes handles
        if isempty(Hf) || ~ishandle(Hf)
            % open figure for calibration data plotting/GUI
            Hf = figure(p.condMatrix.baseIndex+1); clf;
            set(Hf, 'windowstyle','normal', 'toolbar','none', 'menubar','none', 'selectionHighlight','off', ...
                'color',.5*[1 1 1], 'position',[1000,100,600,400]-80);
            set(Hf, 'Name', ['Calib:  ',p.trial.session.file], 'NumberTitle','off')            
        else
            % direct focus to calibration figure & clear
            figure(Hf); % clf;
        end

        if isempty(Ax) || ~ishandle(Ax)
            Ax = axes;
        else
            axes(Ax); cla
        end
        % tune axes to fit
        box off;  axis equal;  hold on;
        try
            % XY pixel locations of all current targets
            allTargs = p.static.tracking.targets.xyPx - p.static.display.ctr(1:2)';
            axis(Ax, 1.3*[min(allTargs(1,:)),max(allTargs(1,:)), min(allTargs(2,:)),max(allTargs(2,:))]);
        end
%         set(Ax, 'plotboxaspectratio',[p.static.display.ctr(1:2),1], 'fontsize',10);
        set(Ax, 'fontsize',10);

    end %getCalibFig


%% updateCalibPlot(p)
    function updateCalibPlot(p)
        % find all recorded fixations that match current viewdist
        n = imag(p.static.tracking.fixations(3,:,srcIdx(1))) == p.static.display.viewdist;        
        
        % XY pixel locations of all current targets 
        allTargs = p.static.tracking.targets.xyPx - p.static.display.ctr(1:2)';
        
        % Direct focus to calibration figure & axes
        % - [Hf] is local persistent variable to figure handle
        getCalibFig;
        
        % color by target location onscreen
        % - convert targ loc to polar, then subdivide r by 3, t by 9
        cols = lines(64);
        
        % plot targets
        plot( allTargs(1,:), -allTargs(2,:), 'd','color',.8*[1 1 1])

        % mark currently active target
        plot( allTargs(1,p.static.tracking.targets.i), -allTargs(2,p.static.tracking.targets.i), 'ro', 'markersize',10, 'linewidth',1.2);
        
        % Report target visibility in gui fig
        if p.trial.tracking.col(4) % rendering params still in p.trial  (this sort of makes sense, but could become confusing)
            title('[- Target visible -]', 'fontweight','bold');
        else
            title('[- Target hidden -]', 'fontweight','normal'); %, 'color',[1,.1,.1]);
        end
        
        
        if any(n)
            % plot fixations
            for i = srcIdx
                % only plot if fixation data present in current transform
                fixTargs = real(p.static.tracking.fixations(1:2, n, i))' - p.static.display.ctr(1:2);
                fixVals  = imag(p.static.tracking.fixations(1:2, n, i))';    % - p.trial.display.ctr(1:2);
                
                if ~all(isnan(fixVals(:)))
                    % unique target locations
                    [uTargs] = unique(fixTargs, 'rows');
                    
                    % color target markers by location on screen     (...crufty)
                    [targTh,targR] = cart2pol(fixTargs(:,1), fixTargs(:,2));
                    % condition polar coords for indexing
                    targTh = wrapTo360(rad2deg(targTh));    targR = targR/p.trial.display.ppd;
                    targColIdx = ceil(targTh/30) + 12*ceil(targR/7.5);
                    targColIdx(targColIdx<=0) = 1; % prevent index error at center
                                        
                    % plot target locations
                    plot( uTargs(:,1), -uTargs(:,2), 'kd')
                    % plot raw data (open circles)
                    scatter(fixVals(:,1)- p.static.display.ctr(1), -(fixVals(:,2)- p.static.display.ctr(2)), [], cols(targColIdx,:), 'markerfacecolor','none','markeredgealpha',.4);
                    
                    % plot calibrated data (filled circles)
                    fixCaled = transformPointsInverse(p.static.tracking.tform(i), fixVals)- p.static.display.ctr(1:2);
                    scatter(fixCaled(:,1), -fixCaled(:,2), [], cols(targColIdx,:), 'filled', 'markeredgecolor','none','markerfacealpha',.4);
                end
            end
        end
        drawnow
    end %updateCalibPlot


%% resetCalibration(p)
    function resetCalibration(p)
        % packaged for easy call/editing
        
        % find all recorded fixations that match current viewdist
        n = imag(p.static.tracking.fixations(3,:,srcIdx(1))) == p.static.display.viewdist;
        % remove any fixation data with matching viewdist
        p.static.tracking.fixations(:,n,:) = [];

        % p.static.tracking.fixations = nan(3, p.static.tracking.minSamples, max(srcIdx));
        p.static.tracking.thisFix = size(p.static.tracking.fixations, 2);   % 0;
        p.static.tracking.setupTargets(); % refresh targets using class method
        updateTarget(p);
%         updateCalibPlot(p);
        
    end %resetCalibration


%% updateTarget(p)
    function updateTarget(p)
        
        if ~isempty(p.static.tracking.nextTarg)
            i = p.static.tracking.nextTarg;
        else
            i = randsample(1:p.static.tracking.targets.nTargets, 1); % first target location
        end
        
        p.static.tracking.targets.i = i;
        ii = find(p.static.tracking.targets.randOrd==i);
        p.static.tracking.nextTarg = p.static.tracking.targets.randOrd(mod(ii, p.static.tracking.targets.nTargets)+1);
        
        % updateCalibPlot(p);
        
    end %updateTarget


%% logFixation(p)
    function logFixation(p)
        if ~p.trial.tracking.col(4)
            fprintf(2, '~!~\tNo fixation logged; targets currently HIDDEN from subject\n~!~\t-- Press [zero] to toggle visibility\n');
        
        else
            p.static.tracking.thisFix = p.static.tracking.thisFix + 1;
            for i = srcIdx
                % Keep target & eye values together using complex numbers:  target == real(xyz), eye == imag(xyz)
                % -- targetXYZ == stimulusXYZ 
                % -- eyeXYZ == [rawEyeXY, viewDist]
                % ** Z will often but not always be same for both **
                %    -- allows targets to be presented in screen-plane or egocentric coords while keeping separate record of viewing distance
                p.static.tracking.fixations(:, p.static.tracking.thisFix, i) = ...
                    [p.static.tracking.targets.xyPx(:,p.static.tracking.targets.i); p.static.tracking.targets.targPos(3,p.static.tracking.targets.i)] + ... % Target position in real component
                    1i.*[p.trial.tracking.posRaw(:,min([i,end])); p.static.display.viewdist]; % Measured eye position in imaginary component
                
            end
                fprintf('.')
        end
    end %logFixation

end %main function


% % % % % % % % %
%% Sub Functions
% % % % % % % % %

