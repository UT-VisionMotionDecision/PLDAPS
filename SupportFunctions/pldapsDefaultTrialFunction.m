function pldapsDefaultTrialFunction(p,state, sn)
%stimulus name is only used for one variable: eyeW
    if nargin<3
        sn='stimulus';
    end
%     if p.trial.display.useGL
%         global GL
%     end
    
    switch state
        % FRAME STATES  (always place these at the top of your switch statement b/c they happen most frequently)
        case p.trial.pldaps.trialStates.frameUpdate
            frameUpdate(p);
            
        case p.trial.pldaps.trialStates.framePrepareDrawing 
            % ...does nothing by default
            %    framePrepareDrawing(p);
            
        case p.trial.pldaps.trialStates.frameDraw
            frameDraw(p,sn);
            
        case p.trial.pldaps.trialStates.frameGLDrawLeft
            % Skip altogether if not enabled
            if p.trial.display.useGL
                % Only pass in the needed display structure
                frameGLDrawLeft(p.trial.display);
            end
            
        case p.trial.pldaps.trialStates.frameGLDrawRight
            % Skip altogether if not enabled & not stereomode
            if p.trial.display.useGL && p.trial.display.stereoMode~=0
                % Only pass in the needed display structure
                frameGLDrawRight(p.trial.display);
            end

        case p.trial.pldaps.trialStates.frameDrawingFinished
            frameDrawingFinished(p);
            
        case p.trial.pldaps.trialStates.frameFlip; 
            frameFlip(p);
            
        % TRIAL STATES
        case p.trial.pldaps.trialStates.trialItiDraw
            trialItiDraw(p);
            % NEED NEW TRIAL/FRAME  state that allows drawing to the screen prior to the intertrial flip
            % that occurs during trialCleanUpandSave. ...would excise that flip all together, but that
            % would leave scraps on the screen when most users expect it to be cleared.
            % ** note, Pause should (optionally?) skip over this drawing step so that an animal doesnt
            %    keep fixating without any ongoing tracking or reward potential!
            
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
            if isfield(p.trial.display, 'useGL') && p.trial.display.useGL
                %   .display.glPerspective == [fovy, aspect, zNear, zFar]
                p.trial.display.glPerspective = [atand(p.trial.display.wHeight/2/p.trial.display.viewdist)*2,...
                    p.trial.display.wWidth/p.trial.display.wHeight,...
                    p.trial.display.zNear,... % near clipping plane (cm)
                    p.trial.display.zFar];  % far clipping plane (cm)
            end
                
    end
end           % % % ****!!!!**** Moved overall function end below all subfunctions (makng them nested functions

% % % % % % % % % % % % % % % 
% % % Sub-functions
% % % % % % % % % % % % % % % 

%---------------------------------------------------------------------% 
%% frameUpdate   (check & refresh keyboard/mouse/analog/eye data)
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
                
            % [D]ebug mode   (...like pause, but does not leave workspace of currently executing trial)
            elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.dKey)
                    disp('stepped into debugger. Type return to start first trial...')
                    keyboard %#ok<MCKBD>
            end
        end
        
        % Poll mouse
        if p.trial.mouse.use
            [cursorX,cursorY,isMouseButtonDown] = GetMouse(p.trial.mouse.windowPtr);
            % Return data in trial struct
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
        % pds.plexon.spikeserver.getSpikes(p);

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
        
        % Grid overlay
        if p.trial.pldaps.draw.grid.use
            Screen('DrawLines', p.trial.display.overlayptr, p.trial.pldaps.draw.grid.tick_line_matrix, 1, p.trial.display.clut.window, p.trial.display.ctr(1:2));
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
            p.trial.timing.photodiodeTimes(:,p.trial.pldaps.draw.photodiode.dataEnd) = [p.trial.ttime p.trial.iFrame];
            p.trial.pldaps.draw.photodiode.dataEnd = p.trial.pldaps.draw.photodiode.dataEnd+1;
            Screen('FillRect', p.trial.display.ptr, [1 1 1]', p.trial.pldaps.draw.photodiode.rect');
        end
    end %frameDraw

    
%---------------------------------------------------------------------% 
%%  frameGLDrawLeft
    function frameGLDrawLeft(ds)
        global GL

        % Switch to 3D mode:
        Screen('BeginOpenGL', ds.ptr);

        % Select stereo draw buffer WITHIN a 3D openGL context!
        % unbind current FBOS first     (per PTB source:  "otherwise bad things can happen...")
        glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, uint32(0))

        fbo = uint32(1); % FBO index for RIGHT eye
        glBindFramebufferEXT(GL.READ_FRAMEBUFFER_EXT, fbo);
        glBindFramebufferEXT(GL.DRAW_FRAMEBUFFER_EXT, fbo);
        glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, fbo);

        % Clear depth (and color?) buffers:
        glClear(GL.DEPTH_BUFFER_BIT);
        
        % Setup camera for this eyes 'view':
        glMatrixMode(GL.MODELVIEW);
        glLoadIdentity;
        % OBSERVER-CENTRIC; (0,0,0) should be observer location
        %   gluLookAt( eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ )
        %   !!**!! OpenGL space z-space is in the negative direction (else z-buffer doesn't work!)
        gluLookAt(ds.obsPos(1)-0.5*ds.ipd*cosd(ds.obsPos(4)), ds.obsPos(2), -(ds.obsPos(3)-.5*ds.ipd*sind(ds.obsPos(4))),...
                  ds.fixPos(1), ds.fixPos(2), -ds.fixPos(3),...
                  ds.upVect(1), ds.upVect(2), ds.upVect(3));

    end%  frameGLDrawLeft


%---------------------------------------------------------------------% 
%%  frameGLDrawRight
    function frameGLDrawRight(ds)
        global GL

        % We are already inside 3D openGL 'BeginOpenGL' mode at this point
        % Select stereo draw buffer WITHIN a 3D openGL context!
        % unbind current FBOS first     (per PTB source:  "otherwise bad things can happen...")
        glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, uint32(0))

        fbo = uint32(2); % FBO index for RIGHT eye
        glBindFramebufferEXT(GL.READ_FRAMEBUFFER_EXT, fbo);
        glBindFramebufferEXT(GL.DRAW_FRAMEBUFFER_EXT, fbo);
        glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, fbo);

        % Clear depth buffers:  (CONFIRMED:  This must be done for each eye on each frame. --TBC)
        glClear(GL.DEPTH_BUFFER_BIT);

        % Setup camera for RIGHT eye 'view':
        glMatrixMode(GL.MODELVIEW);
        glLoadIdentity;
        % OBSERVER-CENTRIC; (0,0,0) should be observer location
        %   gluLookAt( eyeX, eyeY, -eyeZ, centerX, centerY, -centerZ, upX, upY, upZ )
        %   !!**!! OpenGL space z-space is in the negative direction (else z-buffer doesn't work!)
        gluLookAt(ds.obsPos(1)+0.5*ds.ipd*cosd(ds.obsPos(4)), ds.obsPos(2), -(ds.obsPos(3)+.5*ds.ipd*sind(ds.obsPos(4))),...
            ds.fixPos(1), ds.fixPos(2), -ds.fixPos(3),...
            ds.upVect(1), ds.upVect(2), ds.upVect(3));

    end %frameGLDrawRight


%---------------------------------------------------------------------% 
%%  frameDrawingFinished
    function frameDrawingFinished(p)
        % Check for & disable OpenGL mode before any Screen() calls (else will crash)
        if p.trial.display.useGL
            [~, IsOpenGLRendering] = Screen('GetOpenGLDrawMode');
            % NOTE: polling opengl for info is slow; might make sense to go-for-broke here
            % and assume an 'EndOpenGL' call is necessary given .useGL==true. Play it safe for now. --TBC Dec 2017
            if IsOpenGLRendering
                Screen('EndOpenGL', p.trial.display.ptr);
            end
        end

        Screen('DrawingFinished', p.trial.display.ptr);
    end %frameDrawingFinished
    
    
%---------------------------------------------------------------------% 
%%  frameFlip
    function frameFlip(p)
        ft=cell(5,1);
        [ft{:}] = Screen('Flip', p.trial.display.ptr, p.trial.nextFrameTime + p.trial.trstart);
        
        p.trial.timing.flipTimes(:,p.trial.iFrame)=[ft{:}];
         
         % The overlay screen always needs to be initialized with a FillRect call
         if p.trial.display.overlayptr ~= p.trial.display.ptr
            Screen('FillRect', p.trial.display.overlayptr,0);
         end

         p.trial.stimulus.timeLastFrame = p.trial.timing.flipTimes(1,p.trial.iFrame)-p.trial.trstart;

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

        if p.trial.display.useGL
            setupGLPerspective(p.trial.display); % subfunction
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
        

        % These params are all predetermined, so just set them equal to 0,
        % and keep any code post-vblsync to an absolute minimum!  (...yes, even just touching p.trial)
        p.trial.stimulus.timeLastFrame = 0;     % formerly:  vblTime-p.trial.trstart;
        p.trial.ttime  = 0;                     % formerly:  GetSecs - p.trial.trstart;
        p.trial.timing.syncTimeDuration = 0;    % formerly:  p.trial.ttime;
        
        % Sync up with screen refresh before jumping into actual trial
        %   ** this also ensures that the async flip scheduled at the end of the last trial
        %      has had time to complete & won't interfere with future draws/flips
        p.trial.timing.itiFrameCount = Screen('WaitBlanking', p.trial.display.ptr);
        p.trial.trstart = GetSecs;
        
    end %trialPrepare

    
%---------------------------------------------------------------------% 
%%  trialItiDraw
    function p = trialItiDraw(p)
        % Only do the basic drawing commands here
        %   ...e.g. maybe not eye pos, since it will be static
        % Grid overlay
        if p.trial.pldaps.draw.grid.use
            Screen('DrawLines', p.trial.display.overlayptr, p.trial.pldaps.draw.grid.tick_line_matrix, 1, p.trial.display.clut.window, p.trial.display.ctr(1:2));
        end

        
    end
    
    
%---------------------------------------------------------------------%
%%  cleanUpandSave
    function p = cleanUpandSave(p)

        % % %         ft=cell(5,1);
        % % %         [ft{:}] =Screen('Flip', p.trial.display.ptr,0);
        % % %         p.trial.timing.flipTimes(:,p.trial.iFrame)=[ft{:}];
        
        % Schedule a flip to occur at the next possible time, but don't bother waiting around for it.
%         Screen('AsyncFlipBegin', p.trial.display.ptr);
        Screen('Flip', p.trial.display.ptr, 0, [], 1);
        % Whatever was drawn to this screen will be visible throughout the inter-trial interval.
        % This was previously always/only a blank screen, but if you want anything present on
        % this screen, it can now be drawn during the  .trialItiDraw  state.
        % NOTE: This is not a time-critical draw, and async flips do not return a valid timestamp
        %       at time of schedule.
        
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
        p.trial.timing.frameStateChangeTimes    = p.trial.timing.frameStateChangeTimes(:,1:p.trial.iFrame);

        %do a last frameUpdate   (checks & refreshes keyboard/mouse/analog/eye data)
        frameUpdate(p)
        
        % Flush KbQueue
        KbQueueStop();
        KbQueueFlush();

        %will this crash when more samples where created than preallocated?
        % mouse input
        if p.trial.mouse.use
            i0 = p.trial.mouse.samples+1;
            p.trial.mouse.cursorSamples(:,i0:end) = [];
            p.trial.mouse.buttonPressSamples(:,i0:end) = [];
            p.trial.mouse.samplesTimes(:,i0:end) = [];
        end
        
        i0 = p.trial.keyboard.samples+1;
        p.trial.keyboard.samplesTimes(:,i0:end) = [];
        p.trial.keyboard.samplesFrames(:,i0:end) = [];
        p.trial.keyboard.pressedSamples(:,i0:end) = [];
        p.trial.keyboard.firstPressSamples(:,i0:end) = [];
        p.trial.keyboard.firstReleaseSamples(:,i0:end) = [];
        p.trial.keyboard.lastPressSamples(:,i0:end) = [];
        p.trial.keyboard.lastReleaseSamples(:,i0:end) = [];
        
        
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

    
    
    

    %% setupGLPerspective
    function setupGLPerspective(ds)
        global GL
        
        % readibility & avoid digging into this struct over & over
        glP = ds.glPerspective;
        
        % Setup projection matrix for each eye
        % (** this does not change per-eye & [unlikely] between frames, so just do it once here)
        Screen('BeginOpenGL', ds.ptr)
        
        for view = 0%:double(ds.stereoMode>0)
            % All of these settings will apply to BOTH eyes once implimented
            
            % Select stereo draw buffer WITHIN a 3D openGL context!
            % unbind current FBOS first (per PTB source:  "otherwise bad things can happen...")
            glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, uint32(0))
            
            % Bind this view's buffers
            fbo = uint32(view+1);
            glBindFramebufferEXT(GL.READ_FRAMEBUFFER_EXT, fbo);
            glBindFramebufferEXT(GL.DRAW_FRAMEBUFFER_EXT, fbo);
            glBindFramebufferEXT(GL.FRAMEBUFFER_EXT, fbo);
            
            
            % Setup projection for stereo viewing
            glMatrixMode(GL.PROJECTION)
            glLoadIdentity;
            % glPerspective inputs: ( fovy, aspect, zNear, zFar )
            gluPerspective(glP(1), glP(2), glP(3), glP(4));
            
            % Enable proper occlusion handling via depth tests:
            glEnable(GL.DEPTH_TEST);
            
            % Enable alpha-blending for smooth dot drawing:
            glEnable(GL.BLEND);
            glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
            
            % 3D anti-aliasing?
            % NOTE: None of the standard smoothing enables improve rendering of gluDisk or sphere.
            % Only opening PTB window with multisampling (==4) has any effect
            
            % basic colors
            glClearColor(ds.bgColor(1), ds.bgColor(2), ds.bgColor(3), 1);
            glColor4f(1,1,1,1);
            
            % Disable lighting
            glDisable(GL.LIGHTING);
            % glDisable(GL.BLEND);
            
            if ds.goNuts
                % ...or DO ALL THE THINGS!!!!
                % Enable lighting
                glEnable(GL.LIGHTING);
                glEnable(GL.LIGHT0);
                % Set light position:
                glLightfv(GL.LIGHT0,GL.POSITION, [1 2 3 0]);
                % Enable material colors based on glColorfv()
                glEnable(GL.COLOR_MATERIAL);
                glColorMaterial(GL.FRONT_AND_BACK, GL.AMBIENT_AND_DIFFUSE);
                glMaterialf(GL.FRONT_AND_BACK, GL.SHININESS, 48);
                glMaterialfv(GL.FRONT_AND_BACK, GL.SPECULAR, [.8 .8 .8 1]);
            end
        end
        Screen('EndOpenGL', ds.ptr)
    end %setupGLPerspective
    
