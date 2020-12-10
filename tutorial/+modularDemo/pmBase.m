function p = pmBase(p, state, sn)
% function p = modularDemo.pmBase(p, state, n)
% 
% PLDAPS module ("pm") for basic behavioral trial timecourse
% 
% This module operates a behavioral state machine that
% - Controls trial progression based on subject behavior
%   - based on keypress and/or fixation module state (...using: p.trial.pldaps.modNames.currentFix{1} )
%   - timing of progression through each state set in:  [.stateDur]
% - Records timing of transition into each behavioral state:
%   - see: [.statesStartTime]  &  [.statesStartFrame]
% - Interacts with the [p.condMatrix] to manage matrixModule onset & offset,
%   and to send stimulus condition strobed values (through datapixx)
% 
% 
% TIME COURSE OF TRIAL:
% [STATE,   #]  Description.
% ---------------------------
% [WAITFIX, 1]  Wait for fixation (evaluated using [p.checkFixation] method)
%               .stateDur(1)    (**duration not enforced)
%               .waitForGo      [0,1,2], def=0; see logic in  .frameUpdate>>checkState>>WAITFIX
%               .goSignal       eye position and/or Right Shift key
% [HOLDFIX, 2]  Hold fixation prior to stimulus onset
%               .stateDur(2)
% [STIMULUS,3]  Activate stimulus module(s), must maintain fixation
%               .stateDur(3)
% [RESPONSE,4]  Check for response, determine trial completion
%               .stateDur(4)
%               .waitForResp    [0,1,2], def=0; see logic in  .frameUpdate>>checkState>>RESPONSE
% [END,     5]  Log time of trial completion
% [BREAKFIX,6]  End trial without completing task
% 
% 
% ----------------------------------------------------------------
% 2018-xx-xx TBC  Wrote based on prior PLDAPS behavioral state approaches
% 2019-xx-xx TBC  Updated & evolved for use with p.condMatrix
% 2020-12-10 TBC  Clean up & commenting
%                 expanded logic for WAITFIX & RESPONSE states
% 


% Additional usage & examples:
% ---------------------------
% Within another module, one could modify features of the experiment
% based on behavioral state determined in this module with code
% similar to the following:
% 
%  %...inside of another PLDAPS module (e.g. w/in .frameUpdate state):
%     % get behavioral state module name
%     snBehav = p.trial.pldaps.modNames.behavior{1};
%     % modify based on state
%     switch p.trial.(snBehav).state
%         case p.trial.(snBehav).states.HOLDFIX
%             p.trial.(sn).dotSz = 1.5;
%     end
% 

        
switch state
    
    case p.trial.pldaps.trialStates.frameUpdate
        
        checkState(p,sn);  % this is the main work that this module does
        
        
    %case p.trial.pldaps.trialStates.framePrepareDrawing
    
    case p.trial.pldaps.trialStates.trialSetup

        p.trial.(sn).state              = p.trial.(sn).states.WAITFIX;
        p.trial.(sn).statesStartTime    = nan(p.trial.(sn).nstates, 1);
        p.trial.(sn).statesStartFrame   = nan(p.trial.(sn).nstates, 1);
        p.trial.(sn).statesStartTime(p.trial.(sn).state)    = 0;
        p.trial.(sn).statesStartFrame(p.trial.(sn).state)   = 1;
        
        % Ensure current fixation module is ON
        p.trial.(p.trial.pldaps.modNames.currentFix{:}).on = true;
        p.trial.(sn).timestamp = datetime;

        % Ensure STIMULUS stateDur(3) is at least as long as longest active module
        % Not crazy about this hack...its here as a safety net, not SOP.  TBC 2019-08-29
        maxDur = p.trial.(sn).stateDur(3);
        for i = 1:length(p.trial.pldaps.modNames.matrixModule)
            mN = p.trial.pldaps.modNames.matrixModule{i};
            if p.trial.(mN).use
                maxDur = max(p.trial.(mN).modOnDur(end)*p.trial.(sn).scaleDur + p.trial.display.ifi, maxDur);
            end
        end
        p.trial.(sn).stateDur(3) = maxDur; 
        
        
    case p.trial.pldaps.trialStates.trialCleanUpandSave
        % Put any unused matrix conditions back into the order queue
        putBackConds; % Nested Function
                
        
        % EXPT STATES
    case p.trial.pldaps.trialStates.experimentPreOpenScreen
        initParams(p, sn);
        % register behavioral state module name
        p.trial.pldaps.modNames.behavior = {sn};
        
        
    case p.trial.pldaps.trialStates.experimentPostOpenScreen
        % convert state duration into nframes
        p.trial.(sn).stateDurFrames = ceil(p.trial.(sn).stateDur .* p.trial.display.frate);

        % initialize matrix modules with .shown==false
        initModules(p, p.trial.pldaps.modNames.matrixModule);
        % allow stateDur units of [seconds] or [# of display frames]
        if isprop(p.condMatrix,'useFrameDurations') && p.condMatrix.useFrameDurations
            p.trial.(sn).scaleDur = p.trial.display.ifi;
        else
            p.trial.(sn).scaleDur = 1;
        end
        
end

return
% NOTE: Using [return] here instead of [end] allows nested functions
% access to the same workspace as the main function. --TBC 2020

% % % % % % % % % % % %
% Nested-Functions
% % % % % % % % % % % %

%% putBackConds
function putBackConds
    if ~isempty(p.condMatrix)
        p.trial.(sn).condsShown = p.condMatrix.putBack(p);
    end
end % putBackConds


%% checkState
function [] = checkState(p, sn)
% here is where the logic of a trial is controlled

isheld = p.checkFixation(p, p.trial.pldaps.modNames.currentFix{1});
% Set fixation .mode==0 to ignore fixation & always return isheld==true
%   - i.e.  p.trial.(p.trial.pldaps.modNames.currentFix{1}).mode = 0;

thisState = p.trial.(sn).state; % shorthand

% Behavioral state machine
switch thisState
    % wait for fixation acquired
    case p.trial.(sn).states.WAITFIX
        
        % check for 'goSignal' keypress
        if p.trial.(sn).waitForGo
            goSignal = p.trial.keyboard.firstPressQ(p.trial.(sn).goSignal)>0;
        end
        
        switch p.trial.(sn).waitForGo
            case 0
                % advance when fixation acquired (isheld==true)
                go = isheld;
            case 1
                % % advance when fixation acquired (isheld==true) OR designated goSignal detected
                go = isheld || goSignal;
            case 2
                % advance when fixation acquired (isheld==true) AND designated goSignal detected
                go = isheld && goSignal;
            otherwise
                go = false;
        end

        if p.trial.(sn).waitForGoSignal && p.trial.(sn).wait
            if p.trial.keyboard.firstPressQ(p.trial.(sn).goSignal)
                p.trial.(sn).wait = false;
            end
            
        elseif isheld %p.checkFixation(p)
            % Fixation acquired, move on!
            setStateStart(p,sn, p.trial.(sn).states.HOLDFIX)
            
        end
        
        
    case p.trial.(sn).states.HOLDFIX

        % check fixation is maintained
        if ~isheld %~p.checkFixation(p)
            fixationBroken;
        end
        
        % Pre-trial complete, go to stim presentation
        if p.trial.ttime >= ...
                p.trial.(sn).statesStartTime(thisState)...
                + p.trial.(sn).stateDur(thisState)
            % Advance to STIMULUS state
            setStateStart(p,sn, p.trial.(sn).states.STIMULUS);
        end
        
        
    case p.trial.(sn).states.STIMULUS
        
        % check that fixation is maintained
        if ~isheld %~p.checkFixation(p)
            fixationBroken;
        end
        
        % Stim presentation time
        if p.trial.ttime >= ...
                p.trial.(sn).statesStartTime(thisState)...
                + p.trial.(sn).stateDur(thisState)
            % Stimulus is complete.
            
            % Ensure syncs are sent for any matrixModules still 'on'
            % TBC:  May be a time sink and/or dangerous to artificially mark matrixModule
            %       as 'complete' here. Ideally, module durations should be set so that 
            %       this doesn't occur & this check is unnecessary
            for i = 1:length(p.trial.pldaps.modNames.matrixModule)
                mN = p.trial.pldaps.modNames.matrixModule{i};
                if p.trial.(mN).on      % Module offset
                    if p.trial.datapixx.use
                        % send condition index pulse at module offset
                        p.trial.datapixx.strobeQ(end+1) = p.condMatrix.baseIndex + p.trial.(mN).condIndex;
                    end
                    p.trial.(mN).on = false;
                    % only get here by error of a stimulus being left on at end of trial
                    p.trial.(mN).shown = -1;
                end
            end
            
            % Advance to RESPONSE state
            setStateStart(p,sn, p.trial.(sn).states.RESPONSE);
            
        else
            % Activate matrixModule(s) according to trial time
            ttimeStimulus = p.trial.ttime - p.trial.(sn).statesStartTime(thisState);
            
            
            
            % % % % DEBUG/Demo
            % - Move fixation during trial & watch/confirm relocation of fixation window limits
            % - Demo use of p.trial.pldaps.modNames for interaction between modules without hardcoded names
            fixPos = p.trial.(p.trial.pldaps.modNames.currentFix{1}).fixPos;
            fixPos(1) = 1*sin(ttimeStimulus*pi+pi);
            fixPos(2) = 1*cos(ttimeStimulus*pi);
            p.trial.(p.trial.pldaps.modNames.currentFix{1}).fixPos = fixPos;
            
            
            
            for i = 1:length(p.trial.pldaps.modNames.matrixModule)
                mN = p.trial.pldaps.modNames.matrixModule{i};
                
                if ttimeStimulus >= p.trial.(mN).modOnDur(2)*p.trial.(sn).scaleDur
                    % Module offset
                    % send condition index pulse at motion offset
                    if p.trial.datapixx.use && p.trial.(mN).on
                        p.trial.datapixx.strobeQ(end+1) = p.condMatrix.baseIndex + p.trial.(mN).condIndex;
                    end
                    p.trial.(mN).on = false; % past expiration of module duration
                    p.trial.(mN).shown = true;                    
                    
                elseif ttimeStimulus >= p.trial.(mN).modOnDur(1)*p.trial.(sn).scaleDur
                    % Module onset
                    p.trial.(mN).on = true; % module is active
                    % % Cannot send on & offset pulses; for-loop execution too fast for minimum interval between strobe pulses.
                    % % NOTE: Less a factor with Omniplex (rel to Plexon MAP) & use of pds.datapixx.strobeQueue.m
                    % %       Could revisit this if needed, but hasn't been missed & would need solution for unique onset strobe#.
                    % %       -- TBC 2020-10
                end
            end
        end
        
        
    case p.trial.(sn).states.RESPONSE

        % check stateDur elapsed
        timeExpired =   isnan(p.trial.(sn).stateDur(thisState)) || ...
            p.trial.ttime >=  p.trial.(sn).statesStartTime(thisState) + p.trial.(sn).stateDur(thisState);
        
        % check for trial completion
        % - use external response module to poll/detect subject response & toggle [.hasResponse]
        switch p.trial.(sn).waitForResp
            case 0
                % advance when stateDur exceeded, regardless of response state
                endTrial = timeExpired;
            case 1
                % advance when stateDur exceeded OR hasResponse=true
                endTrial = timeExpired || p.trial.(sn).hasResponse;
            case 2
                % advance when stateDur exceeded AND hasResponse=true
                endTrial = timeExpired && p.trial.(sn).hasResponse;
            otherwise
                endTrial = false;
        end
        
        if endTrial
            % give reward
            pds.behavior.reward.give(p);
            
            % set state to END & advance to next trial
            setStateStart(p,sn, p.trial.(sn).states.END);
            p.trial.pldaps.goodtrial = 1;
            p.trial.flagNextTrial = 1;
        end
        
end %behavioral state machine

    % % % % % % % % % % % %
    % Nested-Function (w/in checkState)
    % % % % % % % % % % % %
    function fixationBroken
        % set state to BREAKFIX & advance to next trial
        setStateStart(p,sn, p.trial.(sn).states.BREAKFIX);
        p.trial.pldaps.goodtrial = 0;
        p.trial.flagNextTrial = 1;

        % Put any unused matrix conditions back into the order queue
        % ** NO, don't do this here/repeatedly **
        %    Moved to .trialCleanupAndSave so that single code instance always
        %    runs at end of trial, regardless of exit state.
        % putBackConds; % Nested Function
        return
    end %fixationBroken
    
end %checkState


%% setStateStart
function setStateStart(p,sn, thisState)
    if nargin>2
        p.trial.(sn).state = thisState;
    else
        thisState = p.trial.(sn).state;
    end
    % record timing in sec & frames
    p.trial.(sn).statesStartTime(thisState) = p.trial.ttime;
    p.trial.(sn).statesStartFrame(thisState) = p.trial.iFrame;
end %setStateStart


%% initParams
function initParams(p, sn)
% setup defaults
dstates = struct(...
    'WAITFIX',  1,...
    'HOLDFIX',  2,...
    'STIMULUS', 3,...
    'RESPONSE', 4,...
    'END',      5,...
    'BREAKFIX', 6);

def = struct(...
    'states',   dstates, ...
    'nstates',  numel(fieldnames(dstates)), ...
    'goSignal', KbName('RightShift'), ...
    'waitForGo', 0, ...     % see WAITFIX state for logic
    'waitForResp', 0, ...   % see RESPONSE state for logic
    'hasResponse', false, ... 
    'stateDur', [nan, 0.24, 3, nan]);

% "pldaps requestedStates" for this module
% - done here so that modifications only needbe made once, not everywhere this module is used
rsNames = {'frameUpdate', ...
    'trialSetup','trialCleanUpandSave', ...
    'experimentPreOpenScreen','experimentPostOpenScreen'};
        
% make it so
p.trial.(sn) = pds.applyDefaults(p.trial.(sn), def);
p = pldapsModuleSetStates(p, sn, rsNames);

% backwards compatibility (...use updated [.waitForGo] logic instead)
if isfield(p.trial.(sn),'waitForGoSignal')
    p.trial.(sn).waitForGo = 2*p.trial.(sn).waitForGoSignal;
end

end %initParams


%% initModules
function initModules(p, theseModules)

    for i = 1:length(theseModules)
        mN = theseModules{i};
        p.trial.(mN).shown = false;
    end
end %initModules


end %main function


% % % % % % % % % % % %
%% Sub-Functions
% % % % % % % % % % % %

%%%%%
%%%%%
%%%%%
