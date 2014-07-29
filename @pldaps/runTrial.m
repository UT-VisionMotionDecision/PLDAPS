function dv = runTrial(dv)
    % [PDS,dv] = runTrial(dv,PDS)
    % runs a single trial
    %
    % 03/2013 jly   Wrote hyperflow
    % 03/2014 jk    removed the hyper, added awesome. Used jly's code to get
    % the PLDAPS structure and frame it into a class
    % might change to ASYNC buffer flipping. but won't for now.

    %the trialFunctionHandle
    tfh=str2func(dv.trial.pldaps.trialFunction);
    
    %trial states that are not in a frame are negative, just to allow both
    %to be more independent
    dv.trial.pldaps.trialStates.trialSetup=-1;
    dv.trial.pldaps.trialStates.trialPrepare=-2;
    dv.trial.pldaps.trialStates.trialCleanUpandSave=-3;
    
    %ok, what are the options?
    %we'll make them states
    %is called once after the last frame is done (or even before)
    %get current eyepostion, curser position or keypresses 
    dv.trial.pldaps.trialStates.frameUpdate=1;
    %here you can prepare all drawing, e.g. have the dots move
    %if you need to update to the latest e.g. eyeposition
    %you can still do that later, this could be all expected heavy
    %calculations
    dv.trial.pldaps.trialStates.framePrepareDrawing=2; 
    %once you know you've calculated the final image, draw it
    dv.trial.pldaps.trialStates.frameDraw=3;
    %
    dv.trial.pldaps.trialStates.frameIdlePreLastDraw=4;
    %if there is something that needs updating. here is a fucntion to do it
    %as late as possible
    dv.trial.pldaps.trialStates.frameDrawTimecritical=5;
    %if this function is not used, drawingFinished will be called after
    %frameDraw is done, otherwise drawingFinished will not be called
    dv.trial.pldaps.trialStates.frameDrawingFinished=6;

    %this function gets called once everything got drawn, until it's time
    %to expect (and do) the flip
    dv.trial.pldaps.trialStates.frameIdlePostDraw=7;
    %do the flip (or when async) record the time 
    dv.trial.pldaps.trialStates.frameFlip=8;
    
    dv.trial.currentFrameState=1;    
    
    tfh(dv, dv.trial.pldaps.trialStates.trialSetup);
    
    timeNeeded(dv.trial.pldaps.trialStates.frameUpdate)=0.5;
    timeNeeded(dv.trial.pldaps.trialStates.framePrepareDrawing)=2;
    timeNeeded(dv.trial.pldaps.trialStates.frameDraw)=2;
    timeNeeded(dv.trial.pldaps.trialStates.frameIdlePreLastDraw)=2;
    timeNeeded(dv.trial.pldaps.trialStates.frameDrawTimecritical)=0.5;
    timeNeeded(dv.trial.pldaps.trialStates.frameDrawingFinished)=2;
    timeNeeded(dv.trial.pldaps.trialStates.frameIdlePostDraw)=0.5;
    timeNeeded(dv.trial.pldaps.trialStates.frameFlip)=5;
    timeNeeded=timeNeeded/1000;%convert to seconds

    %will be called just before the trial starts for time critical calls to
    %start data aquisition
    tfh(dv, dv.trial.pldaps.trialStates.trialPrepare);

    dv.trial.framePreLastDrawIdleCount=0;
    dv.trial.framePostLastDrawIdleCount=0;


    % pdsEyelinkGetQueue(dv);
    %%% MAIN WHILE LOOP %%%
    %-------------------------------------------------------------------------%
        while ~dv.trial.flagNextTrial && dv.trial.pldaps.quit == 0
            %go through one frame
            
            %time of the estimated next flip
            dv.trial.nextFrameTime = dv.trial.stimulus.timeLastFrame+dv.trial.display.ifi;

            tfh(dv, dv.trial.pldaps.trialStates.frameUpdate);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.framePrepareDrawing)

            tfh(dv, dv.trial.pldaps.trialStates.framePrepareDrawing);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameDraw);

            tfh(dv, dv.trial.pldaps.trialStates.frameDraw);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
 
            tfh(dv, dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
            dv.trial.framePreLastDrawIdleCount = dv.trial.framePreLastDrawIdleCount +1;
%             dv.trial.ttime = GetSecs - dv.trial.trstart;
%             dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
%             while (dv.trial.remainingFrameTime>sum(timeNeeded(dv.trial.pldaps.trialStates.frameIdlePreLastDraw+1:end)))
%                 tfh(dv, dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
%                 dv.trial.framePreLastDrawIdleCount = dv.trial.framePreLastDrawIdleCount +1;
%                 dv.trial.ttime = GetSecs - dv.trial.trstart;
%                 dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
%             end
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameDrawTimecritical);

            tfh(dv, dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameDrawingFinished);
                  
            tfh(dv, dv.trial.pldaps.trialStates.frameDrawingFinished);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameIdlePostDraw);

            tfh(dv, dv.trial.pldaps.trialStates.frameIdlePostDraw);
            dv.trial.framePostLastDrawIdleCount = dv.trial.framePostLastDrawIdleCount +1;
%             dv.trial.ttime = GetSecs - dv.trial.trstart;
%             dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
%             while (dv.trial.remainingFrameTime>sum(timeNeeded(dv.trial.pldaps.trialStates.frameIdlePostDraw+1:end)))
%                 tfh(dv, dv.trial.pldaps.trialStates.frameIdlePostDraw);
%                 dv.trial.framePostLastDrawIdleCount = dv.trial.framePostLastDrawIdleCount +1;
%                 dv.trial.ttime = GetSecs - dv.trial.trstart;
%                 dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
%             end
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameFlip)
                   

            tfh(dv, dv.trial.pldaps.trialStates.frameFlip);
            %advance to next frame
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameUpdate);           
            dv.trial.iFrame = dv.trial.iFrame + 1;  % update frame index
        end %while Trial running

        tfh(dv, dv.trial.pldaps.trialStates.trialCleanUpandSave);

    end %runTrial
    
    function setTimeAndFrameState(dv,state)
            dv.trial.ttime = GetSecs - dv.trial.trstart;
            dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
            dv.trial.timing.frameStateChangeTimes(dv.trial.currentFrameState,dv.trial.iFrame)=dv.trial.ttime-dv.trial.nextFrameTime+dv.trial.display.ifi;
            dv.trial.currentFrameState=state;        
    end