function pldapsDefaultTrialFunction(p,state)
    switch state
        %trialStates
        case p.trial.pldaps.trialStates.trialSetup
            trialSetup(p);
        case p.trial.pldaps.trialStates.trialPrepare
            trialPrepare(p);
        case p.trial.pldaps.trialStates.trialCleanUpandSave
            cleanUpandSave(p);
        %frameStates
        case p.trial.pldaps.trialStates.frameUpdate
            frameUpdate(p);
        %case p.trial.pldaps.trialStates.framePrepareDrawing 
        %    framePrepareDrawing(p);
        case p.trial.pldaps.trialStates.frameDraw
            frameDraw(p);
        %case p.trial.pldaps.trialStates.frameIdlePreLastDraw
        %    frameIdlePreLastDraw(p);
        %case p.trial.pldaps.trialStates.frameDrawTimecritical;
        %    drawTimecritical(p);
        case p.trial.pldaps.trialStates.frameDrawingFinished;
            frameDrawingFinished(p);
        %case p.trial.pldaps.trialStates.frameIdlePostDraw;
        %    frameIdlePostDraw(p);
        case p.trial.pldaps.trialStates.frameFlip; 
            frameFlip(p);
    end
        
end
%%% get inputs and check behavior%%%
%---------------------------------------------------------------------% 
    function frameUpdate(p)   
        %%TODO: add buffer for Keyboard presses, nouse position and clicks.
        
        %Keyboard    
        [p.trial.keyboard.pressedQ, p.trial.keyboard.firstPressQ, firstRelease, lastPress, lastRelease]=KbQueueCheck(); % fast
        
        if p.trial.keyboard.pressedQ
    %         [p.trial.keyboard.pressedQ,  p.trial.keyboard.firstPressQ]=KbQueueCheck(); % fast
            p.trial.keyboard.samples = p.trial.keyboard.samples+1;
            p.trial.keyboard.samplesTimes(p.trial.keyboard.samples)=GetSecs;
            p.trial.keyboard.samplesFrames(p.trial.keyboard.samples)=p.trial.iFrame;
            p.trial.keyboard.pressedSamples(:,p.trial.keyboard.samples)=p.trial.keyboard.pressedQ;
            p.trial.keyboard.firstPressSamples(:,p.trial.keyboard.samples)=p.trial.keyboard.firstPressQ;
            p.trial.keyboard.firstReleaseSamples(:,p.trial.keyboard.samples)=firstRelease;
            p.trial.keyboard.lastPressSamples(:,p.trial.keyboard.samples)=lastPress;
            p.trial.keyboard.lastReleaseSamples(:,p.trial.keyboard.samples)=lastRelease;
        end        
        
        if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.mKey)
            if p.trial.datapixx.use
                pds.datapixx.analogOut(p.trial.stimulus.rewardTime)
                pds.datapixx.flipBit(p.trial.event.REWARD);
            end
%             p.trial.ttime = GetSecs - p.trial.trstart;
            p.trial.stimulus.timeReward(:,p.trial.stimulus.iReward) = [p.trial.ttime p.trial.stimulus.rewardTime];
            p.trial.stimulus.iReward = p.trial.stimulus.iReward + 1;
            PsychPortAudio('Start', p.trial.sound.reward);
%         elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.uKey)   % U = user selected targets
%             p.trial.targUser = 1;
        elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.pKey)   % P = pause
            p.trial.pldaps.quit = 1;
            ShowCursor;
%             Screen('Flip', p.trial.display.ptr);
        elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.qKey) % Q = quit
%             Screen('Flip', p.trial.display.ptr);
%             p = pdsEyelinkFinish(p);
%             PDS.timing.timestamplog = PsychDataPixx('GetTimestampLog', 1);
            p.trial.pldaps.quit = 2;
            ShowCursor
        elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.dKey) % d=debug
                disp('stepped into debugger. Type return to start first trial...')
                keyboard %#ok<MCKBD>
%             dbstop if warning opticflow:debugger_requested;
%             warning on opticflow:debugger_requested;
%             warning('opticflow:debugger_requested','At your service!');
%             warning off opticflow:debugger_requested;
%             dbclear if warning opticflow:debugger_requested;
        end   
        % get mouse/eyetracker data
        [cursorX,cursorY,isMouseButtonDown] = GetMouse(); % ktz - added isMouseButtonDown, 28Mar2013
        p.trial.mouse.samples = p.trial.mouse.samples+1;
        p.trial.mouse.samplesTimes(p.trial.mouse.samples)=GetSecs;
        p.trial.mouse.cursorSamples(1:2,p.trial.mouse.samples) = [cursorX;cursorY];
        p.trial.mouse.buttonPressSamples(:,p.trial.mouse.samples) = isMouseButtonDown';
        if(p.trial.mouse.useAsEyepos) 
                mInds=(p.trial.mouse.samples-p.trial.pldaps.eyeposMovAv+1):p.trial.mouse.samples;
                p.trial.eyeX = mean(p.trial.mouse.cursorSamples(1,mInds));
                p.trial.eyeY = mean(p.trial.mouse.cursorSamples(2,mInds));
        end
        %get analogData from Datapixx
        pds.datapixx.adc.getData(p);
        %get eyelink data
        pds.eyelink.getQueue(p); 
        %get eyeposition 
%         pdsGetEyePosition(p);
    end %frameUpdate
% 
%     function framePrepareDrawing(p)
%     end %framePrepareDrawing

    %% frameDraw
    function frameDraw(p)
        %this holds the code to draw some stuff to the overlay (using
        %switches, like the grid, the eye Position, etc
        
        %consider moving this stuff to an earlier timepoint, to allow GPU
        %to crunch on this before the real stuff gets added.
        if p.trial.pldaps.draw.grid.use
            Screen('DrawLines',p.trial.display.overlayptr,p.trial.pldaps.draw.grid.tick_line_matrix,1,p.trial.display.clut.window,p.trial.display.ctr(1:2))
        end
        
         %draw the eyepositon to the second srceen only
         %move the color and size parameters to
         %p.trial.pldaps.draw.eyepos?
         if p.trial.pldaps.draw.eyepos.use
            Screen('Drawdots',  p.trial.display.overlayptr, [p.trial.eyeX p.trial.eyeY]', ...
            p.trial.stimulus.eyeW, p.trial.stimulus.colorEyeDot, [0 0],0)
         end
         
         if p.trial.pldaps.draw.photodiode.use && mod(p.trial.iFrame, p.trial.pldaps.draw.photodiode.everyXFrames) == 0
            photodiodecolor = p.trial.display.clut.window;
            p.trial.timing.photodiodeTimes(:,p.trial.pldaps.draw.photodiode.dataEnd) = [p.trial.ttime p.trial.iFrame];
            p.trial.pldaps.draw.photodiode.dataEnd=p.trial.pldaps.draw.photodiode.dataEnd+1;
            Screen('FillRect',  p.trial.display.overlayptr,photodiodecolor, p.trial.pldaps.draw.photodiode.rect')
        end
    end %frameDraw

    %% frameIdlePreLastDraw
%     function frameIdlePreLastDraw(p)
%         %only execute once, since this is the only part atm, this is done at 0
%         if p.trial.framePreLastDrawIdleCount==0    
%         else %if no one stepped in to execute we might as well skip to the next stage
%             p.trial.currentFrameState=p.trial.pldaps.trialStates.frameDrawTimecritical;
%         end
%     end %frameIdlePreLastDraw

%     function drawTimecritical(p)
%     end %drawTimecritical

    function frameDrawingFinished(p)
        Screen('DrawingFinished', p.trial.display.ptr,0,0);
%         Screen('DrawingFinished', p.trial.display.overlayptr);
        %if we're going async, we'd probably do the flip call here, right? but
        %could also do it in the flip either way.
    end %frameDrawingFinished

%     function frameIdlePostDraw(p)
%         if p.trial.framePostLastDrawIdleCount==0  
%         else
%             p.trial.currentFrameState=p.trial.pldaps.trialStates.frameFlip;
%         end
%     end %frameIdlePostDraw

    function frameFlip(p)
%       if mod(p.trial.iFrame,3)==1
         p.trial.timing.flipTimes(:,p.trial.iFrame) = deal(Screen('Flip', p.trial.display.ptr,0));
%       end
         if p.trial.display.movie.create
             %we should skip every nth frame depending on the ration of
             %frame rates, or increase every nth frameduration by 1 every
             %nth frame
%              if p.trial.display.frate > p.trial.display.movie.frameRate
%                  mod(p.trial.iFrame, p.trial.display.frate/p.trial.display.movie.frameRate)>1
%              else
%                  
%              end
%              
%              p.defaultParameters.display.movie.moviePtr
%              p.defaultParameters.display.movie.frameRate
%              frameDuration
             frameDuration=1;
             Screen('AddFrameToMovie', p.trial.display.ptr,[],[],p.trial.display.movie.ptr, frameDuration);
         end
         
         if(p.trial.datapixx.use)
            Screen('FillRect', p.trial.display.overlayptr,0);
         end
         
         p.trial.stimulus.timeLastFrame = p.trial.timing.flipTimes(1,p.trial.iFrame)-p.trial.trstart;
         p.trial.framePreLastDrawIdleCount=0;
         p.trial.framePostLastDrawIdleCount=0;
    end %frameFlip

    function trialSetup(p)
        
        p.trial.timing.flipTimes       = zeros(4,p.trial.pldaps.maxFrames);
        p.trial.timing.frameStateChangeTimes=nan(9,p.trial.pldaps.maxFrames);
        
        if(p.trial.pldaps.draw.photodiode.use)
            p.trial.timing.photodiodeTimes=nan(2,p.trial.pldaps.maxFrames);
            p.trial.pldaps.draw.photodiode.dataEnd=1;
        end
        
        %these are things that are specific to subunits as eyelink,
        %datapixx, mouse and should probabbly be in separarte functions,
        %but I have no logic/structure for that atm.
        
        %setup analogData collection from Datapixx
        pds.datapixx.adc.trialSetup(p);
        
        %call PsychDataPixx('GetPreciseTime') to make sure the clock stay
        %synced
        if p.trial.datapixx.use
            [getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');
            p.trial.timing.datapixxPreciseTime(1:3) = [getsecs, boxsecs, confidence];
        end
        
        %setup a fields for the mouse data
        [~,~,isMouseButtonDown] = GetMouse(); 
        p.trial.mouse.cursorSamples = zeros(2,p.trial.pldaps.maxFrames*1.1);
        p.trial.mouse.buttonPressSamples = zeros(length(isMouseButtonDown),p.trial.pldaps.maxFrames*1.1);
        p.trial.mouse.samplesTimes=zeros(1,p.trial.pldaps.maxFrames*1.1);
        p.trial.mouse.samples = 0;
        
        
        
        %setup assignemnt of eyeposition data to eyeX and eyeY
        %first create the S structs for subsref.
        % Got a big WTF on your face? read up on subsref, subsasgn and substruct
        % we need this to dynamically access data deep inside a multilevel struct
        % without using eval.
        % different approach: have it set by the data collectors
        % themselves?
     
        
    end %trialSetup
    
    function trialPrepare(p)     

        %%% setup PsychPortAudio %%%
        %-------------------------------------------------------------------------%
        % we use the PsychPortAudio pipeline to give auditory feedback because it
        % has less timing issues than Beeper.m -- Beeper freezes flips as long as
        % it is producing sound whereas PsychPortAudio loads a wav file into the
        % buffer and can call it instantly without wasting much compute time.
        pds.audio.clearBuffer(p)


        if p.trial.datapixx.use
            Datapixx RegWrRd;
        end
        


        %%% Initalize Keyboard %%%
        %-------------------------------------------------------------------------%
        pds.keyboard.clearBuffer(p);
        %setup a fields for the keyboard data
        [~, firstPress]=KbQueueCheck();
        p.trial.keyboard.samples = 0;
        p.trial.keyboard.samplesTimes=zeros(1,p.trial.pldaps.maxFrames*1.1);
        p.trial.keyboard.samplesFrames=zeros(1,p.trial.pldaps.maxFrames*1.1);
%         p.trial.keyboard.keyPressSamples = zeros(length(firstPressQ),p.trial.pldaps.maxFrames*1.1);
        p.trial.keyboard.pressedSamples=false(1,p.trial.pldaps.maxFrames*1.1);
        p.trial.keyboard.firstPressSamples = zeros(length(firstPress),p.trial.pldaps.maxFrames*1.1);
        p.trial.keyboard.firstReleaseSamples = zeros(length(firstPress),p.trial.pldaps.maxFrames*1.1);
        p.trial.keyboard.lastPressSamples = zeros(length(firstPress),p.trial.pldaps.maxFrames*1.1);
        p.trial.keyboard.lastReleaseSamples = zeros(length(firstPress),p.trial.pldaps.maxFrames*1.1);
        
        %%% Spike server
        %-------------------------------------------------------------------------%
        [p,spikes] = pds.spikeserver.getSpikes(p); %what are we dowing with the spikes???

        %%% Eyelink Toolbox Setup %%%
        %-------------------------------------------------------------------------%
        % preallocate for all eye samples and event data from the eyelink
        pds.eyelink.startTrial(p);


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
        if p.trial.datapixx.use
            for ii = 1:6
                pds.datapixx.strobe(clocktime(ii));
            end
        end
        p.trial.unique_number = clocktime;    % trial identifier
%         vblTime = Screen('Flip', p.trial.display.ptr,0); 
        p.trial.trstart = GetSecs;
%         p.trial.stimulus.timeLastFrame=vblTime-p.trial.trstart;

        if p.trial.datapixx.use
            p.trial.timing.datapixxStartTime = Datapixx('Gettime');
            p.trial.timing.datapixxTRIALSTART = pds.datapixx.flipBit(p.trial.event.TRIALSTART);  % start of trial (Plexon)
        end

        p.trial.ttime  = GetSecs - p.trial.trstart;
        p.trial.timing.syncTimeDuration = p.trial.ttime;
    end %trialPrepare

    function p = cleanUpandSave(p)
        if p.trial.datapixx.use
            p.trial.datapixx.datapixxstoptime = Datapixx('GetTime');
        end
        p.trial.trialend = GetSecs- p.trial.trstart;

        [p.trial.timing.flipTimes(1,p.trial.iFrame), p.trial.timing.flipTimes(2,p.trial.iFrame), p.trial.timing.flipTimes(3,p.trial.iFrame), p.trial.timing.flipTimes(4,p.trial.iFrame)] = Screen('Flip', p.trial.display.ptr); %#ok<ASGLU>

        %do a last frameUpdate
        frameUpdate(p)
        
        %clean up analogData collection from Datapixx
        pds.datapixx.adc.cleanUpandSave(p);
        
        if(p.trial.pldaps.draw.photodiode.use)
            p.trial.timing.photodiodeTimes(:,p.trial.pldaps.draw.photodiode.dataEnd:end)=[];
        end
        % if isfield(p, 'dp') % FIX ME
        %     p.dp = pds.datapixx.adcStop(p.dp);
        % end

        %% Flush KbQueue %%%
        KbQueueStop();
        KbQueueFlush();

        %will this crash when more samples where created than preallocated?
        % mouse input
        p.trial.mouse.cursorSamples(:,p.trial.mouse.samples+1:end) = [];
        p.trial.mouse.buttonPressSamples(:,p.trial.mouse.samples+1:end) = [];
        p.trial.mouse.samplesTimes(:,p.trial.mouse.samples+1:end) = [];
        
        % mouse input
%         p.trial.keyboard.keyPressSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.samplesTimes(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.samplesFrames(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.pressedSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.firstPressSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.firstReleaseSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.lastPressSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.lastReleaseSamples(:,p.trial.keyboard.samples+1:end) = [];

        % Get spike server spikes
        %---------------------------------------------------------------------%
        if isfield(p.trial, 'spikeserver') && p.trial.spikeserver.use
            try
                [p, p.trial.spikeserver.spikes] = pds.spikeserver.getSpikes(p);

                if ~isempty(p.trial.spikeserver.spikes)
                    plbit = p.trial.event.TRIALSTART + 2;
                    t0 = find(p.trial.spikeserver.spikes(:,1) == 4 & p.trial.spikeserver.spikes(:,2) == plbit, 1, 'first');
                    p.trial.spikeserver.spikes(:,4) = p.trial.spikeserver.spikes(:,4) - p.trial.spikeserver.spikes(t0,4);
%                     PDS.spikes{p.j} = spikes;
                else
%                     PDS.spikes{p.j} = []; % zeros size of spike matrix
                    fprintf('No spikes. Check if server is running\r')
                end

            catch me
                disp(me.message)
            end
        end
        %---------------------------------------------------------------------%

        %% Build PDS STRUCT %%
        p.trial.trialnumber   = p.trial.pldaps.iTrial;

        % system timing
%         p.trial.timing.ptbFliptimes       = p.trial.timing.flipTimes(:,1:p.trial.iFrame);
        p.trial.timing.flipTimes      = p.trial.timing.flipTimes(:,1:p.trial.iFrame);
        p.trial.timing.frameStateChangeTimes    = p.trial.timing.frameStateChangeTimes(:,1:p.trial.iFrame-1);

        % if isfield(p, 'dp') % FIX ME
        %     analogTime = linspace(p.dp.adctstart, p.dp.adctend, size(p.dp.bufferData,2));
        %     PDS.data.datapixxAnalog{p.j} = [analogTime(:) p.dp.bufferData'];
        % end
      
        if p.trial.eyelink.use
            [Q, rowId] = pds.eyelink.saveQueue(p);
            p.trial.eyelink.samples = Q;
            p.trial.eyelink.sampleIds = rowId; % I overwrite everytime because PDStrialTemps get saved after every trial if we for some unforseen reason ever need this for each trial
            p.trial.eyelink.events   = p.trial.eyelink.events(:,~isnan(p.trial.eyelink.events(1,:)));
        end

        % Update Scope
    %     try
    %         pdsScopeUpdate(PDS,p.j)
    %     catch
    %         disp('error updating scope')
    %     end

    end %cleanUpandSave