function p = runTrial(p)
%runTrial    runs a single Trial by calling the function defined in 
%            p.trial.pldaps.trialFunction through different states
%
% 03/2013 jly   Wrote hyperflow
% 03/2014 jk    Used jly's code to get the PLDAPS structure and frame it into a class
%               might change to ASYNC buffer flipping. but won't for now.

    %the trialFunctionHandle
    tfh=str2func(p.trial.pldaps.trialFunction);
    
    %% Initialize state values
    % Different phases in a trial are called trialStates

    % -- States that are executed once on every trial are called "trial states",
    % and their name begins with 'trial'
    %   (...yes, there's some confusing redundancy here...sorry, just go with it.)
    
    % Trial states have a negative value, indiciating that they should not be cycled through
    % on every display frame.
    % Their absolute value generally corresponds to the order in which they occur. However,
    % that sequence is [for the most part] hard-coded in the structure of pldaps run function(s).
    % (i.e. if you change a state from a positive to a negative value it will no longer be 
    % called on every display frame, but that DOES NOT mean that it will get called outside of
    % the frame updating portion of the trial)
    p.trial.pldaps.trialStates.trialSetup = -1;
    p.trial.pldaps.trialStates.trialPrepare = -2;
    
    % ----------- A subset of states are cycled through on every display frame until trial is finished
    
    % -- States that are executed on every display frame are called "frame states",
    % and their name begins with 'frame'.
    % Unless otherwise stated, each frame state is called once per display frame interval (.display.ifi) 
    % They are executed in order accorting to state number:
    
    % 1) frameUpdate:
    %   gets current eyepostion, cursor position, keypresses, etc.
    %   ...do your basic IO checks here
    p.trial.pldaps.trialStates.frameUpdate = 1;
    
    % 2) framePrepareDrawing:
    %   here you can prepare all drawing, e.g. update stimulus positions/features/etc
    %   Do whatever frame-dependent calculations you need here...if you're dropping frames,
    %   try precomputing things in trialSetup, then index into them here with p.trial.iFrame
    p.trial.pldaps.trialStates.framePrepareDrawing = 2; 
    
    % 3) frameDraw:
    %   Do all the drawing
    p.trial.pldaps.trialStates.frameDraw = 3;
    
    % 4) frameDrawingFinished
    %   Tell PTB that all drawing is complete so that it can begin final compositing & shader operations
    p.trial.pldaps.trialStates.frameDrawingFinished = 4;

    % 5) frameFlip
    %   do the flip, record the time 
    p.trial.pldaps.trialStates.frameFlip = 5;
    
    % ----------- After all trial frames have been displayed..

    % -3) trialItiDraw
    %   This is a new state that allows you to draw onto the screen that will remain
    %   visible throughout the intertrial interval. 
    p.trial.pldaps.trialStates.trialItiDraw = -3;

    % -4) trialCleanUpandSave
    %   Bookkeeping, clearing of extraneous variables/arrays created during trial,
    %   dotting of eyes, crossing of tees,...
    p.trial.pldaps.trialStates.trialCleanUpandSave = -4;
    
    
    %% Pre-trial states & tasks
    p.trial.currentFrameState = 1;    
    
    % trialSetup
    tfh(p, p.trial.pldaps.trialStates.trialSetup);
    
    %switch to high priority mode
    if p.trial.pldaps.maxPriority
        oldPriority=Priority;
        maxPriority=MaxPriority('GetSecs');
        if oldPriority < maxPriority
                Priority(maxPriority);
        end
    end

    % trialPrepare
    %   called just before the trial starts for time critical calls
    %   (e.g. to start data aquisition)
    tfh(p, p.trial.pldaps.trialStates.trialPrepare);


    %%% MAIN WHILE LOOP %%%
    %-------------------------------------------------------------------------%
    while ~p.trial.flagNextTrial && p.trial.pldaps.quit == 0
        %go through one frame by calling tfh with the different states.
        % (The time each state is finished will be saved in p.trial.timing.frameStateChangeTimes)
        
        % update frame index (this should have been initialized to 0 before the trial started)
        p.trial.iFrame = p.trial.iFrame + 1;

        % Time of next flip
        p.trial.nextFrameTime = p.trial.stimulus.timeLastFrame + 0.98*p.trial.display.ifi;

        % Start timer for GPU rendering operations
        Screen('GetWindowInfo', p.trial.display.ptr, 5);
        
        % frameUpdate
        tfh(p, p.trial.pldaps.trialStates.frameUpdate);
        
        % framePrepareDrawing
        setTimeAndFrameState(p,p.trial.pldaps.trialStates.framePrepareDrawing)
        tfh(p, p.trial.pldaps.trialStates.framePrepareDrawing);
        
        % frameDraw
        setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameDraw);
        tfh(p, p.trial.pldaps.trialStates.frameDraw);
        
        % frameDrawingFinished
        setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameDrawingFinished);
        tfh(p, p.trial.pldaps.trialStates.frameDrawingFinished);
                
        % frameFlip
        setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameFlip)
        tfh(p, p.trial.pldaps.trialStates.frameFlip);
        
        % Retrieve GPU render time of last frame
        dinfo = Screen('GetWindowInfo', p.trial.display.ptr);
        p.trial.frameRenderTime(p.trial.iFrame) = dinfo.GPULastFrameRenderTime;
        
        %advance to next frame
        setTimeAndFrameState(p, p.trial.pldaps.trialStates.frameUpdate);           

    end %while Trial running

    % trialItiDraw
    %  ** Inherently not a time-critical operation, so no call to setTimeAndFrameState necessary
    %   ...also, setTimeAndFrameState uses current state as an index, so using with this would break
    tfh(p, p.trial.pldaps.trialStates.trialItiDraw);
    
    if p.trial.pldaps.maxPriority
        newPriority=Priority;
        if round(oldPriority) ~= round(newPriority)
            Priority(oldPriority);
        end
        if round(newPriority)<maxPriority
            warning('pldaps:runTrial','Thread priority was degraded by operating system during the trial.')
        end
    end
    
    % trialCleanUpandSave
    tfh(p, p.trial.pldaps.trialStates.trialCleanUpandSave);

end %runTrial
    
function setTimeAndFrameState(p,state)
        p.trial.ttime = GetSecs - p.trial.trstart;
        p.trial.remainingFrameTime = p.trial.nextFrameTime - p.trial.ttime;
        p.trial.timing.frameStateChangeTimes(p.trial.currentFrameState, p.trial.iFrame) = p.trial.ttime - p.trial.nextFrameTime + p.trial.display.ifi;
        p.trial.currentFrameState = state;
end