function dv = runTrial(dv, tfh)
    % [PDS,dv] = runTrial(dv,PDS)
    % runs a single trial
    %
    % 03/2013 jly   Wrote hyperflow
    % 03/2014 jk    removed the hyper, added awesome. Used jly's code to get
    % the PLDAPS structure and frame it into a class
    % might change to ASYNC buffer flipping. but won't for now.

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
%     trialSetup(dv);
    
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
%     trialPrepare(dv);



    dv.trial.framePreLastDrawIdleCount=0;
    dv.trial.framePostLastDrawIdleCount=0;


    dv.trial.prevFrameState=dv.trial.currentFrameState;
    dv.trial.prevTimeLastFrame=dv.trial.stimulus.timeLastFrame;
    dv.trial.prevFrame=dv.trial.iFrame;

    % pdsEyelinkGetQueue(dv);
    %%% MAIN WHILE LOOP %%%
    %-------------------------------------------------------------------------%
        while ~dv.trial.flagNextTrial && dv.trial.pldaps.quit == 0
            %go through one frame
            
            %time of the estimated next flip
            dv.trial.nextFrameTime = dv.trial.stimulus.timeLastFrame+dv.trial.display.ifi;

            % update trial time
%             dv.trial.ttime = GetSecs - dv.trial.trstart;
%             remainingTime=nextFrameTime-dv.trial.ttime;
% 
%             if(dv.trial.prevFrameState~=dv.trial.currentFrameState)
%                     dv.trial.timing.frameStateChangeTimes(dv.trial.prevFrameState,dv.trial.prevFrame)=dv.trial.ttime-dv.trial.prevTimeLastFrame;
%                     dv.trial.prevFrameState=dv.trial.currentFrameState;
%                     dv.trial.prevTimeLastFrame=dv.trial.stimulus.timeLastFrame;
%                     dv.trial.prevFrame=dv.trial.iFrame;
%             end

            tfh(dv, dv.trial.pldaps.trialStates.frameUpdate);
%             frameUpdate(dv);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.framePrepareDrawing)

            tfh(dv, dv.trial.pldaps.trialStates.framePrepareDrawing);
%             framePrepareDrawing(dv);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameDraw);

            tfh(dv, dv.trial.pldaps.trialStates.frameDraw);
%             frameDraw(dv);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
 
            tfh(dv, dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
%             frameIdlePreLastDraw(dv);
            dv.trial.framePreLastDrawIdleCount = dv.trial.framePreLastDrawIdleCount +1;
            dv.trial.ttime = GetSecs - dv.trial.trstart;
            dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
            while (dv.trial.remainingFrameTime>sum(timeNeeded(dv.trial.pldaps.trialStates.frameIdlePreLastDraw+1:end)))
                tfh(dv, dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
%                 frameIdlePreLastDraw(dv);
                dv.trial.framePreLastDrawIdleCount = dv.trial.framePreLastDrawIdleCount +1;
                dv.trial.ttime = GetSecs - dv.trial.trstart;
                dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
            end
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameDrawTimecritical);

            tfh(dv, dv.trial.pldaps.trialStates.frameIdlePreLastDraw);
%             drawTimecritical(dv);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameDrawingFinished);
                  
            tfh(dv, dv.trial.pldaps.trialStates.frameDrawingFinished);
%             frameDrawingFinished(dv);
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameIdlePostDraw);

            tfh(dv, dv.trial.pldaps.trialStates.frameIdlePostDraw);
%             frameIdlePostDraw(dv);
            dv.trial.framePostLastDrawIdleCount = dv.trial.framePostLastDrawIdleCount +1;
            dv.trial.ttime = GetSecs - dv.trial.trstart;
            dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
            while (dv.trial.remainingFrameTime>sum(timeNeeded(dv.trial.pldaps.trialStates.frameIdlePostDraw+1:end)))
                tfh(dv, dv.trial.pldaps.trialStates.frameIdlePostDraw);
%                 frameIdlePostDraw(dv);
                dv.trial.framePostLastDrawIdleCount = dv.trial.framePostLastDrawIdleCount +1;
                dv.trial.ttime = GetSecs - dv.trial.trstart;
                dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
            end
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameFlip)
                   

            tfh(dv, dv.trial.pldaps.trialStates.frameFlip);
%             frameFlip(dv);
            %advance to next frame
            setTimeAndFrameState(dv,dv.trial.pldaps.trialStates.frameUpdate);

        end %while Trial running

%         dv.trial.ttime = GetSecs - dv.trial.trstart;
%         if(dv.trial.prevFrameState~=dv.trial.currentFrameState)
%             dv.trial.timing.frameStateChangeTimes(dv.trial.prevFrameState,dv.trial.prevFrame)=dv.trial.ttime-dv.trial.prevTimeLastFrame;
%             dv.trial.prevFrameState=dv.trial.currentFrameState;
%             dv.trial.prevTimeLastFrame=dv.trial.stimulus.timeLastFrame;
%             dv.trial.prevFrame=dv.trial.iFrame;
%         end

        tfh(dv, dv.trial.pldaps.trialStates.trialCleanUpandSave);
%         dv = cleanUpandSave(dv);

    end %runTrial
    
    function setTimeAndFrameState(dv,state)
            dv.trial.ttime = GetSecs - dv.trial.trstart;
            dv.trial.remainingFrameTime=dv.trial.nextFrameTime-dv.trial.ttime;
            dv.trial.timing.frameStateChangeTimes(dv.trial.currentFrameState,dv.trial.iFrame)=dv.trial.ttime-dv.trial.prevTimeLastFrame;
            dv.trial.currentFrameState=state;        
    end