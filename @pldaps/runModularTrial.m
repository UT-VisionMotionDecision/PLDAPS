function p = runModularTrial(p, replay)
%runModularTrial    runs a single Trial by calling the functions defined in 
%            their substruct (found by pldaps.getModules) and the function
%            defined in p.trial.pldaps.trialFunction through different states
%
% 03/2013 jly   Wrote hyperflow
% 03/2014 jk    Used jly's code to get the PLDAPS structure and frame it into a class
%               might change to ASYNC buffer flipping. but won't for now.
% 03/2016 jk    modular version

    %replay from this side is faily easy, just need to set the ttime
    %(current time in trial). User must still replace frameUpdate functions 
    %to copy the correct data for the other states to use.
    if nargin<2
        replay=false;
    end

    %get all functionHandles that we want to use
    [modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);

    %order the framestates that we will iterate through each trial by their value
    % only positive states are frame states. And they will be called in
    % order of the value. Check comments in pldaps.getReorderedFrameStates
    % for explanations of the default states
    % negative states are special states outside of a frame (trial,
    % experiment, etc)
    [stateValue, stateName] = p.getReorderedFrameStates(p.trial.pldaps.trialStates,moduleRequestedStates);
    nStates=length(stateValue);

    if replay
        runStateforModules(p,'trialReplaySetup',modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
    end
    runStateforModules(p,'trialSetup',modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);

    %switch to high priority mode
    if p.trial.pldaps.maxPriority
        oldPriority=Priority;
        maxPriority=MaxPriority('GetSecs');
        if oldPriority < maxPriority
                Priority(maxPriority);
        end
    end

    %will be called just before the trial starts for time critical calls to
    %start data aquisition
    runStateforModules(p,'trialPrepare',modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);

    %%% MAIN WHILE LOOP %%%
    %-------------------------------------------------------------------------%
    while ~p.trial.flagNextTrial && p.trial.pldaps.quit == 0
        %go through one frame by calling the modules with the different states.
        %Save the times each state is finished.

        %time of the estimated next flip
        if replay
            if p.trial.iFrame==1
                p.trial.stimulus.timeLastFrame = 0;
                p.trial.trstart = p.data{p.trial.pldaps.iTrial}.trstart;
            else
                p.trial.stimulus.timeLastFrame = p.data{p.trial.pldaps.iTrial}.timing.flipTimes(1,p.trial.iFrame-1)-p.trial.trstart;
            end
        end
        p.trial.nextFrameTime = p.trial.stimulus.timeLastFrame+p.trial.display.ifi;

        %iterate through frame states
        for iState=1:nStates
            runStateforModules(p,stateName{iState},modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);

            if p.trial.iFrame>size(p.data{p.trial.pldaps.iTrial}.timing.frameStateChangeTimes,2)
                break;
            end
            if replay
                p.trial.ttime=p.data{p.trial.pldaps.iTrial}.timing.frameStateChangeTimes(iState,p.trial.iFrame)+ p.trial.nextFrameTime-p.trial.display.ifi;
            else
                p.trial.ttime = GetSecs - p.trial.trstart;
            end
            p.trial.remainingFrameTime=p.trial.nextFrameTime-p.trial.ttime;
            p.trial.timing.frameStateChangeTimes(iState,p.trial.iFrame)=p.trial.ttime-p.trial.nextFrameTime+p.trial.display.ifi;
        end

        %advance to next frame, update frame index
        p.trial.iFrame = p.trial.iFrame + 1;
    end %while Trial running
    
	% trialItiDraw
    %  ** Inherently not a time-critical operation, so no call to setTimeAndFrameState necessary
    %   ...also, setTimeAndFrameState uses current state as an index, so using with this would break
    runStateforModules(p, 'trialItiDraw', modules, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs);


    if p.trial.pldaps.maxPriority
        newPriority=Priority;
        if round(oldPriority) ~= round(newPriority)
            Priority(oldPriority);
        end
        if round(newPriority)<maxPriority
            warning('pldaps:runTrial','Thread priority was degraded by operating system during the trial.')
        end
    end

    runStateforModules(p,'trialCleanUpandSave',modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);

end %runModularTrial
