function p = replayTrial(p)
%replayTrial    replays a single Trial by calling the function defined in 
%               p.trial.pldaps.trialFunction through different states
% this is a modified version of pldaps.runTrial
%
% 03/2013 jly   Wrote hyperflow
% 03/2014 jk    Used jly's code to get the PLDAPS structure and frame it into a class
%               might change to ASYNC buffer flipping. but won't for now.

    %the trialFunctionHandle
    tfh=str2func(p.trial.pldaps.trialFunction);
    
    %trial states that are not in a frame are negative, just to allow both
    %to be more independent
    p.trial.pldaps.trialStates.trialSetup=-1;
    p.trial.pldaps.trialStates.trialPrepare=-2;
    p.trial.pldaps.trialStates.trialCleanUpandSave=-3;
    
    %ok, what are the options?
    %we'll make them states
    %is called once after the last frame is done (or even before)
    %get current eyepostion, curser position or keypresses 
    p.trial.pldaps.trialStates.frameUpdate=1;
    %here you can prepare all drawing, e.g. have the dots move
    %if you need to update to the latest e.g. eyeposition
    %you can still do that later, this could be all expected heavy
    %calculations
    p.trial.pldaps.trialStates.framePrepareDrawing=2; 
    %once you know you've calculated the final image, draw it
    p.trial.pldaps.trialStates.frameDraw=3;
    %
    p.trial.pldaps.trialStates.frameIdlePreLastDraw=4;
    %if there is something that needs updating. here is a fucntion to do it
    %as late as possible
    p.trial.pldaps.trialStates.frameDrawTimecritical=5;
    %if this function is not used, drawingFinished will be called after
    %frameDraw is done, otherwise drawingFinished will not be called
    p.trial.pldaps.trialStates.frameDrawingFinished=6;

    %this function gets called once everything got drawn, until it's time
    %to expect (and do) the flip
    p.trial.pldaps.trialStates.frameIdlePostDraw=7;
    %do the flip (or when async) record the time 
    p.trial.pldaps.trialStates.frameFlip=8;
    
    p.trial.currentFrameState=1;    
    
    tfh(p, p.trial.pldaps.trialStates.trialSetup);
    
%     timeNeeded(p.trial.pldaps.trialStates.frameUpdate)=0.5;
%     timeNeeded(p.trial.pldaps.trialStates.framePrepareDrawing)=2;
%     timeNeeded(p.trial.pldaps.trialStates.frameDraw)=2;
%     timeNeeded(p.trial.pldaps.trialStates.frameIdlePreLastDraw)=2;
%     timeNeeded(p.trial.pldaps.trialStates.frameDrawTimecritical)=0.5;
%     timeNeeded(p.trial.pldaps.trialStates.frameDrawingFinished)=2;
%     timeNeeded(p.trial.pldaps.trialStates.frameIdlePostDraw)=0.5;
%     timeNeeded(p.trial.pldaps.trialStates.frameFlip)=5;
%     timeNeeded=timeNeeded/1000;%convert to seconds

    %will be called just before the trial starts for time critical calls to
    %start data aquisition
    tfh(p, p.trial.pldaps.trialStates.trialPrepare);

    p.trial.framePreLastDrawIdleCount=0;
    p.trial.framePostLastDrawIdleCount=0;


    % pdsEyelinkGetQueue(dv);
    %%% MAIN WHILE LOOP %%%
    %-------------------------------------------------------------------------%
        while ~p.trial.flagNextTrial && p.trial.pldaps.quit == 0
            %go through one frame
            
            %time of the estimated next flip
            p.trial.nextFrameTime = p.trial.stimulus.timeLastFrame+p.trial.display.ifi;

            tfh(p, p.trial.pldaps.trialStates.frameUpdate);
            setTimeAndFrameState(p,p.trial.pldaps.trialStates.framePrepareDrawing)

            tfh(p, p.trial.pldaps.trialStates.framePrepareDrawing);
            setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameDraw);

            tfh(p, p.trial.pldaps.trialStates.frameDraw);
            setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameIdlePreLastDraw);
 
            tfh(p, p.trial.pldaps.trialStates.frameIdlePreLastDraw);
            p.trial.framePreLastDrawIdleCount = p.trial.framePreLastDrawIdleCount +1;
%             dv.trial.ttime = GetSecs - dv.trial.trstart;
%             dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
%             while (dv.trial.remainingFrameTime>sum(timeNeeded(dv.trial.pldaps.trialStates.frameIdlePreLastDraw+1:end)))
%                 tfh(dv, dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
%                 dv.trial.framePreLastDrawIdleCount = dv.trial.framePreLastDrawIdleCount +1;
%                 dv.trial.ttime = GetSecs - dv.trial.trstart;
%                 dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
%             end
            setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameDrawTimecritical);

            tfh(p, p.trial.pldaps.trialStates.frameIdlePreLastDraw);
            setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameDrawingFinished);
                  
            tfh(p, p.trial.pldaps.trialStates.frameDrawingFinished);
            setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameIdlePostDraw);

            tfh(p, p.trial.pldaps.trialStates.frameIdlePostDraw);
            p.trial.framePostLastDrawIdleCount = p.trial.framePostLastDrawIdleCount +1;
%             dv.trial.ttime = GetSecs - dv.trial.trstart;
%             dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
%             while (dv.trial.remainingFrameTime>sum(timeNeeded(dv.trial.pldaps.trialStates.frameIdlePostDraw+1:end)))
%                 tfh(dv, dv.trial.pldaps.trialStates.frameIdlePostDraw);
%                 dv.trial.framePostLastDrawIdleCount = dv.trial.framePostLastDrawIdleCount +1;
%                 dv.trial.ttime = GetSecs - dv.trial.trstart;
%                 dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
%             end
            setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameFlip)
                   

            tfh(p, p.trial.pldaps.trialStates.frameFlip);
            %advance to next frame
            setTimeAndFrameState(p,p.trial.pldaps.trialStates.frameUpdate);           
            p.trial.iFrame = p.trial.iFrame + 1;  % update frame index
        end %while Trial running

        tfh(p, p.trial.pldaps.trialStates.trialCleanUpandSave);

    end %runTrial
    
    function setTimeAndFrameState(p,state)
            p.trial.ttime=p.data{p.trial.pldaps.iTrial}.timing.frameStateChangeTimes(p.trial.currentFrameState,p.trial.iFrame)+ p.trial.nextFrameTime-p.trial.display.ifi;
            p.trial.remainingFrameTime=p.trial.nextFrameTime-p.trial.ttime;
            p.trial.timing.frameStateChangeTimes(p.trial.currentFrameState,p.trial.iFrame)=p.trial.ttime-p.trial.nextFrameTime+p.trial.display.ifi;
            p.trial.currentFrameState=state;        
    end