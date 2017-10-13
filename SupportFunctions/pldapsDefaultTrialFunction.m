function pldapsDefaultTrialFunction(p,state, sn)
%stimulus name is only used for one variable: eyeW
    if nargin<3
        sn='stimulus';
    end

    switch state
        %frameStates
        case p.trial.pldaps.trialStates.frameUpdate
            frameUpdate(p);
        case p.trial.pldaps.trialStates.framePrepareDrawing 
        %    framePrepareDrawing(p);
        case p.trial.pldaps.trialStates.frameDraw
            frameDraw(p,sn);
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
        case p.trial.pldaps.trialStates.experimentPostOpenScreen
            if ~isfield(p.trial.(sn), 'eyeW')
                p.trial.(sn).eyeW = 8;
            end
            if ~isField(p.trial,'event')
                defaultBitNames(p);
            end
            %defaultColors get's called by pldaps.openScreen since overlay2
            %got introduced
            if ~isfield(p.defaultParameters.display,'humanCLUT')
                defaultColors(p);
            end
    end
end

% % % % % % % % % % % % % % % 
% % % Sub-functions
% % % % % % % % % % % % % % % 

%---------------------------------------------------------------------% 
%% frameUpdate
    function frameUpdate(p)   
        %%TODO: add buffer for Keyboard presses, mouse position and clicks.
        
        % Check keyboard    
        [p.trial.keyboard.pressedQ, p.trial.keyboard.firstPressQ, firstRelease, lastPress, lastRelease]=KbQueueCheck(); % fast
        
        if p.trial.keyboard.pressedQ || any(firstRelease)
            p.trial.keyboard.samples = p.trial.keyboard.samples+1;
            p.trial.keyboard.samplesTimes(p.trial.keyboard.samples) = GetSecs;
            p.trial.keyboard.samplesFrames(p.trial.keyboard.samples) = p.trial.iFrame;
            p.trial.keyboard.pressedSamples(:,p.trial.keyboard.samples) = p.trial.keyboard.pressedQ;
            p.trial.keyboard.firstPressSamples(:,p.trial.keyboard.samples) = p.trial.keyboard.firstPressQ;
            p.trial.keyboard.firstReleaseSamples(:,p.trial.keyboard.samples) = firstRelease;
            p.trial.keyboard.lastPressSamples(:,p.trial.keyboard.samples) = lastPress;
            p.trial.keyboard.lastReleaseSamples(:,p.trial.keyboard.samples) = lastRelease;
        end
        
        % Some standard PLDAPS key functions
        if any(p.trial.keyboard.firstPressQ)

            % [M]anual reward
            if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.mKey)
                  pds.behavior.reward.give(p);
                              
            % [P]ause
            elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.pKey)   
                p.trial.pldaps.quit = 1;
                ShowCursor;

            % [Q]uit
            elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.qKey)
                p.trial.pldaps.quit = 2;
                ShowCursor;
                
            % [D]ebug mode   (...like pause, but doesn't leave workspace of currently executing trial function)
            elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.dKey) % d=debug
                    disp('stepped into debugger. Type return to start first trial...')
                    keyboard %#ok<MCKBD>
            end
        end
        
        % Poll mouse
        if p.trial.mouse.use
            [cursorX,cursorY,isMouseButtonDown] = GetMouse(p.trial.mouse.windowPtr); % ktz - added isMouseButtonDown, 28Mar2013
            % Pass out data
            p.trial.mouse.samples = p.trial.mouse.samples+1;
            p.trial.mouse.samplesTimes(p.trial.mouse.samples)=GetSecs;
            p.trial.mouse.cursorSamples(1:2,p.trial.mouse.samples) = [cursorX;cursorY];
            p.trial.mouse.buttonPressSamples(:,p.trial.mouse.samples) = isMouseButtonDown';
            % Use as eyepos if requested
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
    
%---------------------------------------------------------------------% 
%%  framePrepareDrawing    
	function framePrepareDrawing(p)  %#ok<*DEFNU>
    % This is where you should compute your stimulus features for the next frame.
    % At this point, the eye position, datapixx info, spike signals (maybe more)
    % should be as up-to-date as they are going to be before the next display frame
    
    % Currently empty in the pldapsDefaultTrialFunction by design.

	end %framePrepareDrawing

%---------------------------------------------------------------------% 
%%  frameDraw
    function frameDraw(p, sn)
        %this holds the code to draw some stuff to the overlay (using
        %switches, like the grid, the eye Position, etc
                
        %did the background color change? Usually already applied after
        %frameFlip, but make sure we're not missing anything
        if any(p.trial.pldaps.lastBgColor~=p.trial.display.bgColor)
        	Screen('FillRect', p.trial.display.ptr,p.trial.display.bgColor);
            p.trial.pldaps.lastBgColor = p.trial.display.bgColor;
        end
        
        % Grid overlay
        if p.trial.pldaps.draw.grid.use
            Screen('DrawLines',p.trial.display.overlayptr,p.trial.pldaps.draw.grid.tick_line_matrix,1,p.trial.display.clut.window,p.trial.display.ctr(1:2));
        end
        
        % Framerate history
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
        
         % Eye positon
         if p.trial.pldaps.draw.eyepos.use
            Screen('Drawdots', p.trial.display.overlayptr, [p.trial.eyeX p.trial.eyeY]', ...
                    p.trial.(sn).eyeW, p.trial.display.clut.eyepos, [0 0],0);
         end
         if p.trial.mouse.use && p.trial.pldaps.draw.cursor.use
            Screen('Drawdots',  p.trial.display.overlayptr,  p.trial.mouse.cursorSamples(1:2,p.trial.mouse.samples), ...
            p.trial.(sn).eyeW, p.trial.display.clut.cursor, [0 0],0);
         end
         
         % Photodiode sync flash
         if p.trial.pldaps.draw.photodiode.use && mod(p.trial.iFrame, p.trial.pldaps.draw.photodiode.everyXFrames) == 0
            photodiodecolor = [1 1 1];
            p.trial.timing.photodiodeTimes(:,p.trial.pldaps.draw.photodiode.dataEnd) = [p.trial.ttime p.trial.iFrame];
            p.trial.pldaps.draw.photodiode.dataEnd=p.trial.pldaps.draw.photodiode.dataEnd+1;
            Screen('FillRect',  p.trial.display.ptr,photodiodecolor, p.trial.pldaps.draw.photodiode.rect');
        end
    end %frameDraw

    
%---------------------------------------------------------------------% 
%%  frameIdlePreLastDraw
% % These don't appear to have ever been implimented, and will soon be deleted unless someone speaks up.
% %     --TBC 2017-10  
%     function frameIdlePreLastDraw(p)
%         %only execute once, since this is the only part atm, this is done at 0
%         if p.trial.framePreLastDrawIdleCount==0    
%         else %if no one stepped in to execute we might as well skip to the next stage
%             p.trial.currentFrameState=p.trial.pldaps.trialStates.frameDrawTimecritical;
%         end
%     end %frameIdlePreLastDraw


%---------------------------------------------------------------------% 
%%  frameDrawTimecritical
% % These don't appear to have ever been implimented, and will soon be deleted unless someone speaks up.
% %     --TBC 2017-10
%     function drawTimecritical(p)
%     end %drawTimecritical


%---------------------------------------------------------------------% 
%%  frameDrawingFinished
    function frameDrawingFinished(p)
        Screen('DrawingFinished', p.trial.display.ptr);
%         Screen('DrawingFinished', p.trial.display.overlayptr);
    end %frameDrawingFinished

    
%---------------------------------------------------------------------% 
%%  frameIdlePostDraw
% % These don't appear to have ever been implimented, and will soon be deleted unless someone speaks up.
% %     --TBC 2017-10
%     function frameIdlePostDraw(p)
%         if p.trial.framePostLastDrawIdleCount==0  
%         else
%             p.trial.currentFrameState=p.trial.pldaps.trialStates.frameFlip;
%         end
%     end %frameIdlePostDraw
    

%---------------------------------------------------------------------% 
%%  frameFlip
    function frameFlip(p)
        ft=cell(5,1);
        [ft{:}] = Screen('Flip', p.trial.display.ptr, p.trial.nextFrameTime + p.trial.trstart);

        p.trial.timing.flipTimes(:,p.trial.iFrame)=[ft{:}];

        % Calls like this should be excised to some type of "movie module"
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

    
%---------------------------------------------------------------------% 
%%  trialSetup
    function trialSetup(p)
        p.trial.timing.flipTimes       = zeros(5,p.trial.pldaps.maxFrames);
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
        p.trial.keyboard.samples = 0;
        p.trial.keyboard.samplesTimes=zeros(1,round(p.trial.pldaps.maxFrames*1.1));
        p.trial.keyboard.samplesFrames=zeros(1,round(p.trial.pldaps.maxFrames*1.1));
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

        
    end %trialSetup
    
    
%---------------------------------------------------------------------% 
%%  trialPrepare
    function trialPrepare(p)     

        %%% setup PsychPortAudio %%%
        %-------------------------------------------------------------------------%
        % we use the PsychPortAudio pipeline to give auditory feedback because it
        % has less timing issues than Beeper.m -- Beeper freezes flips as long as
        % it is producing sound whereas PsychPortAudio loads a wav file into the
        % buffer and can call it instantly without wasting much compute time.
        pds.audio.clearBuffer(p)

        % Ensure anything in the datapixx buffer has been pushed/updated
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

        clocktime = fix(clock);
        if p.trial.datapixx.use
            for ii = 1:6
                p.trial.datapixx.unique_number_time(ii,:)=pds.datapixx.strobe(clocktime(ii));
            end
        end
        p.trial.unique_number = clocktime;    % trial identifier
        
        if p.trial.datapixx.use
            p.trial.timing.datapixxStartTime = Datapixx('Gettime');
            p.trial.timing.datapixxTRIALSTART = pds.datapixx.flipBit(p.trial.event.TRIALSTART,p.trial.pldaps.iTrial);  % start of trial (Plexon)
        end
        
        
        %ensure background color is correct
        % Not again!?! Why are we doing this over and over? --TBC
        % % %         Screen('FillRect', p.trial.display.ptr,p.trial.display.bgColor);
        % % %         p.trial.pldaps.lastBgColor = p.trial.display.bgColor;

        % Why do we keep flipping outside of the trial? ...this makes it impossible to maintain
        % continuous features (fixation marks, etc) across trials.
        % ...this *will* be addressed soon. --TBC 2017-10         
        vblTime = Screen('Flip', p.trial.display.ptr,0); 
        p.trial.trstart = vblTime;
        p.trial.stimulus.timeLastFrame = vblTime-p.trial.trstart;

        p.trial.ttime  = GetSecs - p.trial.trstart;
        p.trial.timing.syncTimeDuration = p.trial.ttime;
    end %trialPrepare


%---------------------------------------------------------------------% 
%%  cleanUpandSave
    function p = cleanUpandSave(p)

        ft=cell(5,1);
        [ft{:}] =Screen('Flip', p.trial.display.ptr,0);
        p.trial.timing.flipTimes(:,p.trial.iFrame)=[ft{:}];
        % Why do we keep flipping outside of the trial? ...this makes it impossible to maintain
        % continuous features (fixation marks, etc) across trials.
        % ...this *will* be addressed soon. --TBC 2017-10
        
        % Execute all time-sesitive tasks first
        if p.trial.datapixx.use
            p.trial.datapixx.datapixxstoptime = Datapixx('GetTime');
        end
        p.trial.trialend = GetSecs- p.trial.trstart;

        %clean up analogData collection from Datapixx
        pds.datapixx.adc.cleanUpandSave(p);
         if p.trial.datapixx.use
            p.trial.timing.datapixxTRIALEND = pds.datapixx.flipBit(p.trial.event.TRIALEND,p.trial.pldaps.iTrial);  % start of trial (Plexon)
        end
        
        if(p.trial.pldaps.draw.photodiode.use)
            p.trial.timing.photodiodeTimes(:,p.trial.pldaps.draw.photodiode.dataEnd:end)=[];
        end
        
        
        p.trial.trialnumber   = p.trial.pldaps.iTrial;
        p.trial.timing.flipTimes      = p.trial.timing.flipTimes(:,1:p.trial.iFrame);
        p.trial.timing.frameStateChangeTimes    = p.trial.timing.frameStateChangeTimes(:,1:p.trial.iFrame-1);

        %do a last frameUpdate
        frameUpdate(p)
        
        % Flush KbQueue
        KbQueueStop();
        KbQueueFlush();

        %will this crash when more samples where created than preallocated?
        % mouse input
        if p.trial.mouse.use
            p.trial.mouse.cursorSamples(:,p.trial.mouse.samples+1:end) = [];
            p.trial.mouse.buttonPressSamples(:,p.trial.mouse.samples+1:end) = [];
            p.trial.mouse.samplesTimes(:,p.trial.mouse.samples+1:end) = [];
        end
        
        p.trial.keyboard.samplesTimes(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.samplesFrames(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.pressedSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.firstPressSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.firstReleaseSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.lastPressSamples(:,p.trial.keyboard.samples+1:end) = [];
        p.trial.keyboard.lastReleaseSamples(:,p.trial.keyboard.samples+1:end) = [];
        
        
        %---------------------------------------------------------------------%
        % Plexon specific:
        % Get spike server spikes
        if p.trial.plexon.spikeserver.use
            try
                pds.plexon.spikeserver.getSpikes(p);
            catch me
                disp(me.message)
            end
        end
     
        
        %---------------------------------------------------------------------%
        % Eyelink specific:
        if p.trial.eyelink.use
            [Q, rowId] = pds.eyelink.saveQueue(p);
            p.trial.eyelink.samples = Q;
            p.trial.eyelink.sampleIds = rowId; % I overwrite everytime because PDStrialTemps get saved after every trial if we for some unforseen reason ever need this for each trial
            p.trial.eyelink.events   = p.trial.eyelink.events(:,~isnan(p.trial.eyelink.events(1,:)));
        end

        
       % reward system
       pds.behavior.reward.cleanUpandSave(p);
       
    end %cleanUpandSave
