function pldapsDefaultTrialFunction(p,state)
    switch state
        %frameStates
        case p.trial.pldaps.trialStates.frameUpdate
            frameUpdate(p);
        case p.trial.pldaps.trialStates.framePrepareDrawing 
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
            
        %trialStates
        case p.trial.pldaps.trialStates.trialSetup
            trialSetup(p);
        case p.trial.pldaps.trialStates.trialPrepare
            trialPrepare(p);
        case p.trial.pldaps.trialStates.trialCleanUpandSave
            cleanUpandSave(p);
        %only availiable if p.trial.pldaps.trialMasterFunction = 'runModularTrial'
        case p.trial.pldaps.trialStates.experimentAfterTrials
            if ~isempty(p.trial.pldaps.experimentAfterTrialsFunction)
               h=str2func(p.trial.pldaps.experimentAfterTrialsFunction);
               h(p, state)
            end
    end
end
%%% get inputs and check behavior%%%
%---------------------------------------------------------------------% 
    function frameUpdate(p)   
        %%TODO: add buffer for Keyboard presses, nouse position and clicks.
        
        %Keyboard    
        [p.trial.keyboard.pressedQ, p.trial.keyboard.firstPressQ, firstRelease, lastPress, lastRelease]=KbQueueCheck(); % fast
        
        if p.trial.keyboard.pressedQ || any(firstRelease)
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
        
        if any(p.trial.keyboard.firstPressQ)
            if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.mKey)
                  pds.behavior.reward.give(p);
%                 if p.trial.datapixx.use
%                     pds.datapixx.analogOut(p.trial.stimulus.rewardTime)
%                     pds.datapixx.flipBit(p.trial.event.REWARD,p.trial.pldaps.iTrial);
%                 end
%     %             p.trial.ttime = GetSecs - p.trial.trstart;
%                 p.trial.stimulus.timeReward(:,p.trial.stimulus.iReward) = [p.trial.ttime p.trial.stimulus.rewardTime];
%                 p.trial.stimulus.iReward = p.trial.stimulus.iReward + 1;
%                 PsychPortAudio('Start', p.trial.sound.reward);
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
        end
        % get mouse/eyetracker data
        if p.trial.mouse.use
            [cursorX,cursorY,isMouseButtonDown] = GetMouse(p.trial.mouse.windowPtr); % ktz - added isMouseButtonDown, 28Mar2013
            p.trial.mouse.samples = p.trial.mouse.samples+1;
            p.trial.mouse.samplesTimes(p.trial.mouse.samples)=GetSecs;
            p.trial.mouse.cursorSamples(1:2,p.trial.mouse.samples) = [cursorX;cursorY];
            p.trial.mouse.buttonPressSamples(:,p.trial.mouse.samples) = isMouseButtonDown';
            if(p.trial.mouse.useAsEyepos) 
                if p.trial.pldaps.eyeposMovAv==1
                    p.trial.eyeX = p.trial.mouse.cursorSamples(1,p.trial.mouse.samples);
                    p.trial.eyeY = p.trial.mouse.cursorSamples(2,p.trial.mouse.samples);
                else
                    mInds=(p.trial.mouse.samples-p.trial.pldaps.eyeposMovAv+1):p.trial.mouse.samples;
                    p.trial.eyeX = mean(p.trial.mouse.cursorSamples(1,mInds));
                    p.trial.eyeY = mean(p.trial.mouse.cursorSamples(2,mInds));
                end
            end
        end
        %get analogData from Datapixx
        pds.datapixx.adc.getData(p);
        %get eyelink data
        pds.eyelink.getQueue(p); 
        %get plexon spikes
%         pds.plexon.spikeserver.getSpikes(p);
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
        
        %did the background color change? Usually already applied after
        %frameFlip, but make sure we're not missing anything
        if any(p.trial.pldaps.lastBgColor~=p.trial.display.bgColor)
        	Screen('FillRect', p.trial.display.ptr,p.trial.display.bgColor);
            p.trial.pldaps.lastBgColor = p.trial.display.bgColor;
        end
        
        if p.trial.pldaps.draw.grid.use
            Screen('DrawLines',p.trial.display.overlayptr,p.trial.pldaps.draw.grid.tick_line_matrix,1,p.trial.display.clut.window,p.trial.display.ctr(1:2));
        end
        
        %draw a history of fast inter frame intervals
        if p.trial.pldaps.draw.framerate.use && p.trial.iFrame>2
            %update data
            p.trial.pldaps.draw.framerate.data=circshift(p.trial.pldaps.draw.framerate.data,-1);
            p.trial.pldaps.draw.framerate.data(end)=p.trial.timing.flipTimes(1,p.trial.iFrame-1)-p.trial.timing.flipTimes(1,p.trial.iFrame-2);
            %plot
            if p.trial.pldaps.draw.framerate.show 
                %adjust y limit
                p.trial.pldaps.draw.framerate.sf.ylims=[0 max(max(p.trial.pldaps.draw.framerate.data), 2*p.trial.display.ifi)];
                %current ifi is solid black
                pds.pldaps.draw.screenPlot(p.trial.pldaps.draw.framerate.sf, p.trial.pldaps.draw.framerate.sf.xlims, [p.trial.display.ifi p.trial.display.ifi], p.trial.display.clut.blackbg, '-');
                %2 ifi reference is 5 black dots
                pds.pldaps.draw.screenPlot(p.trial.pldaps.draw.framerate.sf, p.trial.pldaps.draw.framerate.sf.xlims(2)*(0:0.25:1), ones(1,5)*2*p.trial.display.ifi, p.trial.display.clut.blackbg, '.');
                %0 ifi reference is 5 black dots
                pds.pldaps.draw.screenPlot(p.trial.pldaps.draw.framerate.sf, p.trial.pldaps.draw.framerate.sf.xlims(2)*(0:0.25:1), zeros(1,5), p.trial.display.clut.blackbg, '.');
                %data are red dots
                pds.pldaps.draw.screenPlot(p.trial.pldaps.draw.framerate.sf, 1:p.trial.pldaps.draw.framerate.nFrames, p.trial.pldaps.draw.framerate.data', p.trial.display.clut.redbg, '.');
            end
         end
        
         %draw the eyepositon to the second srceen only
         %move the color and size parameters to
         %p.trial.pldaps.draw.eyepos?
         if p.trial.pldaps.draw.eyepos.use
            Screen('Drawdots',  p.trial.display.overlayptr, [p.trial.eyeX p.trial.eyeY]', ...
            p.trial.stimulus.eyeW, p.trial.display.clut.eyepos, [0 0],0);
         end
         if p.trial.mouse.use && p.trial.pldaps.draw.cursor.use
            Screen('Drawdots',  p.trial.display.overlayptr,  p.trial.mouse.cursorSamples(1:2,p.trial.mouse.samples), ...
            p.trial.stimulus.eyeW, p.trial.display.clut.cursor, [0 0],0);
         end
         
         if p.trial.pldaps.draw.photodiode.use && mod(p.trial.iFrame, p.trial.pldaps.draw.photodiode.everyXFrames) == 0
%             photodiodecolor = p.trial.display.clut.window;
            photodiodecolor = [1 1 1];
            p.trial.timing.photodiodeTimes(:,p.trial.pldaps.draw.photodiode.dataEnd) = [p.trial.ttime p.trial.iFrame];
            p.trial.pldaps.draw.photodiode.dataEnd=p.trial.pldaps.draw.photodiode.dataEnd+1;
            Screen('FillRect',  p.trial.display.ptr,photodiodecolor, p.trial.pldaps.draw.photodiode.rect');
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
             if p.trial.display.frate > p.trial.display.movie.frameRate
                 thisframe = mod(p.trial.iFrame, p.trial.display.frate/p.trial.display.movie.frameRate)>0;
             else
                 thisframe=true;
             end

             if thisframe
                 frameDuration=1;
                 Screen('AddFrameToMovie', p.trial.display.ptr,[],[],p.trial.display.movie.ptr, frameDuration);
             end
         end
                  
         %did the background color change?
         %we're doing it here to make sure we don't overwrite anything
         %but this tyically causes a one frame delay until it's applied
         %i.e. when it's set in frame n, it changes when frame n+1 flips
         %otherwise we could trust users not to draw before
         %frameDraw, but we'll check again at frameDraw to be sure
         if any(p.trial.pldaps.lastBgColor~=p.trial.display.bgColor)
             Screen('FillRect', p.trial.display.ptr,p.trial.display.bgColor);
             p.trial.pldaps.lastBgColor = p.trial.display.bgColor;
         end
         
         if p.trial.display.overlayptr ~= p.trial.display.ptr
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
        
        %call PsychDataPixx('GetPreciseTime') to make sure the clocks stay
        %synced
        if p.trial.datapixx.use
            [getsecs, boxsecs, confidence] = PsychDataPixx('GetPreciseTime');
            p.trial.timing.datapixxPreciseTime(1:3) = [getsecs, boxsecs, confidence];
        end
        
        %setup a fields for the keyboard data
%         [~, firstPress]=KbQueueCheck();
        p.trial.keyboard.samples = 0;
        p.trial.keyboard.samplesTimes=zeros(1,round(p.trial.pldaps.maxFrames*1.1));
        p.trial.keyboard.samplesFrames=zeros(1,round(p.trial.pldaps.maxFrames*1.1));
%         p.trial.keyboard.keyPressSamples = zeros(length(firstPressQ),round(p.trial.pldaps.maxFrames*1.1));
        p.trial.keyboard.pressedSamples=false(1,round(p.trial.pldaps.maxFrames*1.1));
        p.trial.keyboard.firstPressSamples = zeros(p.trial.keyboard.nCodes,round(p.trial.pldaps.maxFrames*1.1));
        p.trial.keyboard.firstReleaseSamples = zeros(p.trial.keyboard.nCodes,round(p.trial.pldaps.maxFrames*1.1));
        p.trial.keyboard.lastPressSamples = zeros(p.trial.keyboard.nCodes,round(p.trial.pldaps.maxFrames*1.1));
        p.trial.keyboard.lastReleaseSamples = zeros(p.trial.keyboard.nCodes,round(p.trial.pldaps.maxFrames*1.1));
        
        %setup a fields for the mouse data
        if p.trial.mouse.use
            [~,~,isMouseButtonDown] = GetMouse(); 
            p.trial.mouse.cursorSamples = zeros(2,round(round(p.trial.pldaps.maxFrames*1.1)));
            p.trial.mouse.buttonPressSamples = zeros(length(isMouseButtonDown),round(round(p.trial.pldaps.maxFrames*1.1)));
            p.trial.mouse.samplesTimes=zeros(1,round(round(p.trial.pldaps.maxFrames*1.1)));
            p.trial.mouse.samples = 0;
        end
        
        %%% Eyelink Toolbox Setup %%%
        %-------------------------------------------------------------------------%
        % preallocate for all eye samples and event data from the eyelink
        pds.eyelink.startTrial(p);
        
        %%% Spike server
        %-------------------------------------------------------------------------%
%         [p,spikes] = pds.plexon.spikeserver.getSpikes(p); %what are we dowing with the spikes???
        p.trial.plexon.spikeserver.spikeCount=0;
        pds.plexon.spikeserver.getSpikes(p); %save all spikes that arrives in the inter trial interval

        
        %%% prepare reward system
        pds.behavior.reward.trialSetup(p);
        
        %%% prepare to plot framerate history on screen
        if p.trial.pldaps.draw.framerate.use           
            p.trial.pldaps.draw.framerate.nFrames=round(p.trial.pldaps.draw.framerate.nSeconds/p.trial.display.ifi);
            p.trial.pldaps.draw.framerate.data=zeros(p.trial.pldaps.draw.framerate.nFrames,1); %holds the data
            sf.startPos=round(p.trial.display.w2px'.*p.trial.pldaps.draw.framerate.location + [p.trial.display.pWidth/2 p.trial.display.pHeight/2]);
            sf.size=p.trial.display.w2px'.*p.trial.pldaps.draw.framerate.size;    
            sf.window=p.trial.display.overlayptr;
            sf.xlims=[1 p.trial.pldaps.draw.framerate.nFrames];
            sf.ylims=  [0 2*p.trial.display.ifi];
            sf.linetype='-';
            
            p.trial.pldaps.draw.framerate.sf=sf;
        end

%         %setup assignemnt of eyeposition data to eyeX and eyeY
%         %first create the S structs for subsref.
%         % Got a big WTF on your face? read up on subsref, subsasgn and substruct
%         % we need this to dynamically access data deep inside a multilevel struct
%         % without using eval.
%         % different approach: have it set by the data collectors
%         % themselves?
     
        
    end %trialSetup
    
    function trialPrepare(p)     

        %%% setup PsychPortAudio %%%
        %-------------------------------------------------------------------------%
        % we use the PsychPortAudio pipeline to give auditory feedback because it
        % has less timing issues than Beeper.m -- Beeper freezes flips as long as
        % it is producing sound whereas PsychPortAudio loads a wav file into the
        % buffer and can call it instantly without wasting much compute time.
        pds.audio.clearBuffer(p)


%TODO        %do we need this?
        if p.trial.datapixx.use
            Datapixx RegWrRd;
        end
        


        %%% Initalize Keyboard %%%
        %-------------------------------------------------------------------------%
        pds.keyboard.clearBuffer(p);
        
        %%% Eyelink Toolbox Setup %%%
        %-------------------------------------------------------------------------%
        % preallocate for all eye samples and event data from the eyelink
        pds.eyelink.startTrialPrepare(p);


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
%TODO move into a pds.plexon.startTrial(p) file. Also just sent the data along the trialStart flax, or a  least after?        
        clocktime = fix(clock);
        if p.trial.datapixx.use
            for ii = 1:6
                p.trial.datapixx.unique_number_time(ii,:)=pds.datapixx.strobe(clocktime(ii));
            end
        end
        p.trial.unique_number = clocktime;    % trial identifier
        
        %TODO move into a pds.plexon.startTrial(p) file? Or is this a generic
%datapixx thing? not really....
        if p.trial.datapixx.use
            p.trial.timing.datapixxStartTime = Datapixx('Gettime');
            p.trial.timing.datapixxTRIALSTART = pds.datapixx.flipBit(p.trial.event.TRIALSTART,p.trial.pldaps.iTrial);  % start of trial (Plexon)
        end
        
%%check reconstruction
        %old
%                 p.trial.trstart = GetSecs;
        %new

        %ensure background color is correct
        Screen('FillRect', p.trial.display.ptr,p.trial.display.bgColor);
        p.trial.pldaps.lastBgColor = p.trial.display.bgColor;
         
        vblTime = Screen('Flip', p.trial.display.ptr,0); 
        p.trial.trstart = vblTime;
        p.trial.stimulus.timeLastFrame=vblTime-p.trial.trstart;

        p.trial.ttime  = GetSecs - p.trial.trstart;
        p.trial.timing.syncTimeDuration = p.trial.ttime;
    end %trialPrepare

    function p = cleanUpandSave(p)
%TODO move to pds.datapixx.cleanUpandSave
        [p.trial.timing.flipTimes(:,p.trial.iFrame)] = deal(Screen('Flip', p.trial.display.ptr));
        if p.trial.datapixx.use
            p.trial.datapixx.datapixxstoptime = Datapixx('GetTime');
        end
        p.trial.trialend = GetSecs- p.trial.trstart;

%         [p.trial.timing.flipTimes(:,p.trial.iFrame)] = deal(Screen('Flip', p.trial.display.ptr));

        %do a last frameUpdate
        frameUpdate(p)
        
%TODO move to pds.datapixx.cleanUpandSave
        %clean up analogData collection from Datapixx
        pds.datapixx.adc.cleanUpandSave(p);
         if p.trial.datapixx.use
            p.trial.timing.datapixxTRIALEND = pds.datapixx.flipBit(p.trial.event.TRIALEND,p.trial.pldaps.iTrial);  % start of trial (Plexon)
        end
        
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
        if p.trial.mouse.use
            p.trial.mouse.cursorSamples(:,p.trial.mouse.samples+1:end) = [];
            p.trial.mouse.buttonPressSamples(:,p.trial.mouse.samples+1:end) = [];
            p.trial.mouse.samplesTimes(:,p.trial.mouse.samples+1:end) = [];
        end
        
%         p.trial.keyboard.keyPressSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.samplesTimes(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.samplesFrames(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.pressedSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.firstPressSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.firstReleaseSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.lastPressSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.lastReleaseSamples(:,p.trial.keyboard.samples+1:end) = [];

%TODO move to pds.plexon.cleanUpandSave
        % Get spike server spikes
        %---------------------------------------------------------------------%
        if p.trial.plexon.spikeserver.use
            try
                pds.plexon.spikeserver.getSpikes(p);
            catch me
                disp(me.message)
            end
        end
%             end
%             try
%                 [p, p.trial.plexon.spikeserver.spikes] = pds.plexon.spikeserver.getSpikes(p);
% 
%                 if ~isempty(p.trial.spikeserver.spikes)
%                     plbit = p.trial.event.TRIALSTART + 2;
%                     t0 = find(p.trial.spikeserver.spikes(:,1) == 4 & p.trial.spikeserver.spikes(:,2) == plbit, 1, 'first');
%                     p.trial.plexon.spikeserver.spikes(:,4) = p.trial.plexon.spikeserver.spikes(:,4) - p.trial.plexon.spikeserver.spikes(t0,4);
% %                     PDS.spikes{p.j} = spikes;
%                 else
% %                     PDS.spikes{p.j} = []; % zeros size of spike matrix
%                     fprintf('No spikes. Check if server is running\r')
%                 end
% 
%             catch me
%                 disp(me.message)
%             end
%         end
        %---------------------------------------------------------------------%

        p.trial.trialnumber   = p.trial.pldaps.iTrial;

        % system timing
        p.trial.timing.flipTimes      = p.trial.timing.flipTimes(:,1:p.trial.iFrame);
        p.trial.timing.frameStateChangeTimes    = p.trial.timing.frameStateChangeTimes(:,1:p.trial.iFrame-1);
     
%TODO move to pds.eyelink.cleanUpandSave
        if p.trial.eyelink.use
            [Q, rowId] = pds.eyelink.saveQueue(p);
            p.trial.eyelink.samples = Q;
            p.trial.eyelink.sampleIds = rowId; % I overwrite everytime because PDStrialTemps get saved after every trial if we for some unforseen reason ever need this for each trial
            p.trial.eyelink.events   = p.trial.eyelink.events(:,~isnan(p.trial.eyelink.events(1,:)));
        end

        
       %reward system
       pds.behavior.reward.cleanUpandSave(p);
       
        % Update Scope
    %     try
    %         pdsScopeUpdate(PDS,p.j)
    %     catch
    %         disp('error updating scope')
    %     end

    end %cleanUpandSave