function pldapsDefaultTrialFunction(dv,state)
    switch state
        %trialStates
        case dv.trial.pldaps.trialStates.trialSetup
            trialSetup(dv);
        case dv.trial.pldaps.trialStates.trialPrepare
            trialPrepare(dv);
        case dv.trial.pldaps.trialStates.trialCleanUpandSave
            cleanUpandSave(dv);
        %frameStates
        case dv.trial.pldaps.trialStates.frameUpdate
            frameUpdate(dv);
        %case dv.trial.pldaps.trialStates.framePrepareDrawing 
        %    framePrepareDrawing(dv);
        case dv.trial.pldaps.trialStates.frameDraw
            frameDraw(dv);
        %case dv.trial.pldaps.trialStates.frameIdlePreLastDraw
        %    frameIdlePreLastDraw(dv);
        %case dv.trial.pldaps.trialStates.frameDrawTimecritical;
        %    drawTimecritical(dv);
        case dv.trial.pldaps.trialStates.frameDrawingFinished;
            frameDrawingFinished(dv);
        %case dv.trial.pldaps.trialStates.frameIdlePostDraw;
        %    frameIdlePostDraw(dv);
        case dv.trial.pldaps.trialStates.frameFlip; 
            frameFlip(dv);
    end
        
end
%%% get inputs and check behavior%%%
%---------------------------------------------------------------------% 
    function frameUpdate(dv)   
        %%TODO: add buffer for Keyboard presses, nouse position and clicks.
        
        %Keyboard    
        [dv.trial.keyboard.pressedQ,  dv.trial.keyboard.firstPressQ]=KbQueueCheck(); % fast
        if  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.mKey)
            if dv.trial.datapixx.use
                pds.datapixx.analogOut(dv.trial.stimulus.rewardTime)
                pds.datapixx.flipBit(dv.trial.event.REWARD);
            end
%             dv.trial.ttime = GetSecs - dv.trial.trstart;
            dv.trial.stimulus.timeReward(:,dv.trial.iReward) = [dv.trial.ttime dv.trial.stimulus.rewardTime];
            dv.trial.stimulus.iReward = dv.trial.iReward + 1;
            PsychPortAudio('Start', dv.trial.sound.reward);
%         elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.uKey)   % U = user selected targets
%             dv.trial.targUser = 1;
        elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.pKey)   % P = pause
            dv.trial.pldaps.quit = 1;
            ShowCursor;
%             Screen('Flip', dv.trial.display.ptr);
        elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.qKey) % Q = quit
%             Screen('Flip', dv.trial.display.ptr);
%             dv = pdsEyelinkFinish(dv);
%             PDS.timing.timestamplog = PsychDataPixx('GetTimestampLog', 1);
            dv.trial.pldaps.quit = 2;
            ShowCursor
        elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.dKey) % d=debug
                disp('stepped into debugger. Type return to start first trial...')
                keyboard %#ok<MCKBD>
%             dbstop if warning opticflow:debugger_requested;
%             warning on opticflow:debugger_requested;
%             warning('opticflow:debugger_requested','At your service!');
%             warning off opticflow:debugger_requested;
%             dbclear if warning opticflow:debugger_requested;
        end   
        % get mouse/eyetracker data
        [dv.trial.cursorX,dv.trial.cursorY,dv.trial.isMouseButtonDown] = GetMouse(); % ktz - added isMouseButtonDown, 28Mar2013
        %get eyeposition
        pdsGetEyePosition(dv, true);
    end %frameUpdate
% 
%     function framePrepareDrawing(dv)
%     end %framePrepareDrawing

    %% frameDraw
    function frameDraw(dv)
        %this holds the code to draw some stuff to the overlay (using
        %switches, like the grid, the eye Position, etc
        
        %consider moving this stuff to an earlier timepoint, to allow GPU
        %to crunch on this before the real stuff gets added.
        if dv.trial.pldaps.draw.grid.use
            Screen('DrawLines',dv.trial.display.overlayptr,dv.trial.pldaps.draw.grid.tick_line_matrix,1,dv.trial.display.clut.window,dv.trial.display.ctr(1:2))
        end
        
         %draw the eyepositon to the second srceen only
         %move the color and size parameters to
         %dv.trial.pldaps.draw.eyepos?
         if dv.trial.pldaps.draw.eyepos.use
            Screen('Drawdots',  dv.trial.display.overlayptr, [dv.trial.eyeX dv.trial.eyeY]', ...
            dv.trial.stimulus.eyeW, dv.trial.stimulus.colorEyeDot, [0 0],0)
         end
         
         if dv.trial.pldaps.draw.photodiode.use && mod(dv.trial.iFrame, dv.trial.pldaps.draw.photodiode.everyXFrames) == 0
            photodiodecolor = dv.trial.display.clut.window;
            dv.trial.timing.photodiodeTimes(:,dv.trial.pldaps.draw.photodiode.dataEnd) = [dv.trial.ttime dv.trial.iFrame];
            dv.trial.pldaps.draw.photodiode.dataEnd=dv.trial.pldaps.draw.photodiode.dataEnd+1;
            Screen('FillRect',  dv.trial.display.overlayptr,photodiodecolor, dv.trial.pldaps.draw.photodiode.rect')
        end
    end %frameDraw

    %% frameIdlePreLastDraw
%     function frameIdlePreLastDraw(dv)
%         %only execute once, since this is the only part atm, this is done at 0
%         if dv.trial.framePreLastDrawIdleCount==0    
%         else %if no one stepped in to execute we might as well skip to the next stage
%             dv.trial.currentFrameState=dv.trial.pldaps.trialStates.frameDrawTimecritical;
%         end
%     end %frameIdlePreLastDraw

%     function drawTimecritical(dv)
%     end %drawTimecritical

    function frameDrawingFinished(dv)
        Screen('DrawingFinished', dv.trial.display.ptr);
        Screen('DrawingFinished', dv.trial.display.overlayptr);
        %if we're going async, we'd probably do the flip call here, right? but
        %could also do it in the flip either way.
    end %frameDrawingFinished

%     function frameIdlePostDraw(dv)
%         if dv.trial.framePostLastDrawIdleCount==0  
%         else
%             dv.trial.currentFrameState=dv.trial.pldaps.trialStates.frameFlip;
%         end
%     end %frameIdlePostDraw

    function frameFlip(dv)
        [dv.trial.timing.flipTimes(1,dv.trial.iFrame), dv.trial.timing.flipTimes(2,dv.trial.iFrame), dv.trial.timing.flipTimes(3,dv.trial.iFrame), dv.trial.timing.flipTimes(4,dv.trial.iFrame)] = Screen('Flip', dv.trial.display.ptr,0); %#ok<ASGLU>
    %     if dv.disp.photodiode && mod(dv.trial.iFrame, dv.disp.photodiodeFrames) == 0
    %             photodiodecolor = dv.disp.clut.window;
    %             photodiodeTimes(dv.trial.iPhotodiode,:) = [dv.trial.ttime dv.trial.iFrame+1];
    %             dv.trial.iPhotodiode = dv.trial.iPhotodiode + 1;
    %         else
    %             photodiodecolor = dv.disp.clut.bg;
    %         end
    %         
    %         Screen('FillRect', dv.trial.display.overlayptr,photodiodecolor*ones(3,1), dv.disp.photodiodeRect')
        
            if(dv.trial.datapixx.use)
                Screen('FillRect', dv.trial.display.overlayptr,0);
            end
            %%% DATAPIXX BOOLEAN FLIP %%%

            dv.trial.stimulus.timeLastFrame = dv.trial.timing.flipTimes(3,dv.trial.iFrame)-dv.trial.trstart;
            dv.trial.framePreLastDrawIdleCount=0;
            dv.trial.framePostLastDrawIdleCount=0;
    %        dv.trial.timing.frameStateChangeTimesFlip1(2,dv.trial.iFrame)=toc;
    end %frameFlip

    function trialSetup(dv)
        
        dv.trial.timing.flipTimes       = zeros(4,dv.trial.stimulus.nframes);
        dv.trial.timing.frameStateChangeTimes=nan(9,dv.trial.stimulus.nframes);
        
        if(dv.trial.pldaps.draw.photodiode.use)
            dv.trial.timing.photodiodeTimes=nan(2,dv.trial.stimulus.nframes);
            dv.trial.pldaps.draw.photodiode.dataEnd=1;
        end
    end %trialSetup
    
    function trialPrepare(dv)     

        %%% setup PsychPortAudio %%%
        %-------------------------------------------------------------------------%
        % we use the PsychPortAudio pipeline to give auditory feedback because it
        % has less timing issues than Beeper.m -- Beeper freezes flips as long as
        % it is producing sound whereas PsychPortAudio loads a wav file into the
        % buffer and can call it instantly without wasting much compute time.
        pds.audio.clearBuffer(dv)


        if dv.trial.datapixx.use
            Datapixx RegWrRd;
        end
        


        %%% Initalize Keyboard %%%
        %-------------------------------------------------------------------------%
        pds.keyboard.clearBuffer(dv);

        %%% Spike server
        %-------------------------------------------------------------------------%
        [dv,spikes] = pds.spikeserver.getSpikes(dv); %what are we dowing with the spikes???

        %%% Eyelink Toolbox Setup %%%
        %-------------------------------------------------------------------------%
        % preallocate for all eye samples and event data from the eyelink
        pds.eyelink.startTrial(dv);


        %%% START OF TRIAL TIMING %%
        %-------------------------------------------------------------------------%
        % record start of trial in Datapixx, Mac & Plexon
        % each device has a separate clock

        % At the beginning of each trial, strobe a unique number to the plexon
        % through the Datapixx to identify each trial. Often the Stimulus display
        % will be running for many trials before the recording begins so this lets
        % the plexon rig sync up its first trial with whatever trial number is on
        % for stimulus display.
        % SYNC clocks
        clocktime = fix(clock);
        if dv.trial.datapixx.use
            for ii = 1:6
                pds.datapixx.strobe(clocktime(ii));
            end
        end
        dv.trial.unique_number = clocktime;    % trial identifier
        [ig, ig, dv.trial.stimulus.timeLastFrame] = Screen('Flip', dv.trial.display.ptr,0); %#ok<ASGLU>
        dv.trial.trstart = GetSecs;
        dv.trial.stimulus.timeLastFrame=dv.trial.stimulus.timeLastFrame-dv.trial.trstart;

        if dv.trial.datapixx.use
            dv.trial.timing.datapixxStartTime = Datapixx('Gettime');
            pds.datapixx.flipBit(dv.trial.event.TRIALSTART);  % start of trial (Plexon)
        end
        if dv.trial.eyelink.use
            dv.trial.timing.eyelinkStartTime = Eyelink('TrackerTime');
            Eyelink('message', 'TRIALSTART');
        end

        dv.trial.ttime  = GetSecs - dv.trial.trstart;
        dv.trial.timing.syncTimeDuration = dv.trial.ttime;
    end %trialPrepare

    function dv = cleanUpandSave(dv)
        if dv.trial.datapixx.use
            dv.trial.datapixx.datapixxstoptime = Datapixx('GetTime');
        end
        dv.trial.trialend = GetSecs- dv.trial.trstart;

        [dv.trial.timing.flipTimes(1,dv.trial.iFrame), dv.trial.timing.flipTimes(2,dv.trial.iFrame), dv.trial.timing.flipTimes(3,dv.trial.iFrame), dv.trial.timing.flipTimes(4,dv.trial.iFrame)] = Screen('Flip', dv.trial.display.ptr); %#ok<ASGLU>

        if(dv.trial.pldaps.draw.photodiode.use)
            dv.trial.timing.photodiodeTimes(:,dv.trial.pldaps.draw.photodiode.dataEnd:end)=[];
        end
        % if isfield(dv, 'dp') % FIX ME
        %     dv.dp = pds.datapixx.adcStop(dv.dp);
        % end

        %% Flush KbQueue %%%
        KbQueueStop();
        KbQueueFlush();


        % Get spike server spikes
        %---------------------------------------------------------------------%
        if isfield(dv.trial, 'spikeserver') && dv.trial.spikeserver.use
            try
                [dv, dv.trial.spikeserver.spikes] = pds.spikeserver.getSpikes(dv);

                if ~isempty(dv.trial.spikeserver.spikes)
                    plbit = dv.trial.event.TRIALSTART + 2;
                    t0 = find(dv.trial.spikeserver.spikes(:,1) == 4 & dv.trial.spikeserver.spikes(:,2) == plbit, 1, 'first');
                    dv.trial.spikeserver.spikes(:,4) = dv.trial.spikeserver.spikes(:,4) - dv.trial.spikeserver.spikes(t0,4);
%                     PDS.spikes{dv.j} = spikes;
                else
%                     PDS.spikes{dv.j} = []; % zeros size of spike matrix
                    fprintf('No spikes. Check if server is running\r')
                end

            catch me
                disp(me.message)
            end
        end
        %---------------------------------------------------------------------%

        %% Build PDS STRUCT %%
        dv.trial.trialnumber   = dv.trial.pldaps.iTrial;

        % system timing
%         dv.trial.timing.ptbFliptimes       = dv.trial.timing.flipTimes(:,1:dv.trial.iFrame);
        dv.trial.timing.flipTimes      = dv.trial.timing.flipTimes(:,1:dv.trial.iFrame);
        dv.trial.timing.frameStateChangeTimes    = dv.trial.timing.frameStateChangeTimes(:,1:dv.trial.iFrame-1);

        % if isfield(dv, 'dp') % FIX ME
        %     analogTime = linspace(dv.dp.adctstart, dv.dp.adctend, size(dv.dp.bufferData,2));
        %     PDS.data.datapixxAnalog{dv.j} = [analogTime(:) dv.dp.bufferData'];
        % end
      
        if dv.trial.eyelink.use
            [Q, rowId] = pds.eyelink.saveQueue(dv);
            dv.trial.eyelink.samples = Q;
            dv.trial.eyelink.sampleIds = rowId; % I overwrite everytime because PDStrialTemps get saved after every trial if we for some unforseen reason ever need this for each trial
            dv.trial.eyelink.events   = dv.trial.eyelink.events(:,~isnan(dv.trial.eyelink.events(1,:)));
        end

        % Update Scope
    %     try
    %         pdsScopeUpdate(PDS,dv.j)
    %     catch
    %         disp('error updating scope')
    %     end

    end %cleanUpandSave