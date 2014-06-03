classdef pldaps < handle
 properties
    defaultParameters

    conditions %cell array with a struct like defaultParameters that only hold condition specific changes or additions

    trial %will get all variables from defaultParameters + correct conditions cell merged. This will get saved automatically. 
          %You can add calculated paraneters to this struct, e.g. the
          %actual eyeposition used for caculating the frame, etc.
    data
 end

 methods
    function dv = pldaps(varargin)
        %classdefaults: load from structure
        defaults{1}=load('pldaps/pldapsClassDefaultParameters');
        fn=fieldnames(defaults{1});
        if length(fn)>1
             error('pldaps:pldaps', 'The classes internal default parameter struct should only have one fieldname');
        end
        defaults{1}=defaults{1}.(fn{1});
        defaultsNames{1}=fn{1};
        
        %rigdefaults: load from prefs?
        defaults{2}=getpref('pldaps');
        defaultsNames{2}='pldapsRigPrefs';
        
        dv.defaultParameters=params(defaults,defaultsNames);
        
        %unnecassary, but we'll allow to save parameters in a rig
        %struct, rather than the prefs, as that's a little more
        %conveniant
        if isField(dv.defaultParameters,'pldaps.rigParameters')
            defaults{3}=load(dv.defaultParameters.pldaps.rigParameters);
            fn=fieldnames(defaults{3});
            if length(fn)>1
                error('pldaps:pldaps', 'The rig default parameter struct should only have one fieldname');
            end
            defaults{3}=defaults{3}.(fn{1});
            defaultsNames{3}=fn{1};
             
            dv.defaultParameters.addLevels(defaults(3),defaultsNames(3));
        end
        
        
        %handle input to the constructor
        %if an input is a struct, this is added to the defaultParameters. 
        %if an input is a cell. this is set as the conditions
        
        %It's contents will overrule previous parameters
        %the first nonStruct is expected to be the subject's name
        %the second nonStruct is expected to be the experiment functionname
        structIndex=cellfun(@isstruct,varargin);
        if any(structIndex)
            if sum(structIndex)>1
                error('pldaps:pldaps', 'Only one struct allowed as input.');
            end
            constructorStruct=varargin{structIndex};
        else
            constructorStruct=struct;
        end

        cellIndex=cellfun(@iscell,varargin);
        if any(cellIndex)
            if sum(cellIndex)>1
                error('pldaps:pldaps', 'Only one cell allowed as input.');
            end
            dv.conditions=varargin{cellIndex};
        end
        
        if nargin>4
            error('pldaps:pldaps', 'Only four inputs allowed for now: subject, experimentSetupFile, a struct of parameters and a cell with a struct of parameters for each trial.');
        end
        subjectSet=false;
        for iArgin=1:nargin
            if ~isstruct(varargin{iArgin})
                if ~subjectSet  %set experiment file
                    constructorStruct.session.subject=varargin{iArgin};
                    subjectSet=true;
                else
                    constructorStruct.session.experimentSetupFile=varargin{iArgin};
                end
            end
            
        end       
        dv.defaultParameters.addLevels({constructorStruct, struct},{'ConstructorInputDefaults', 'SessionParameters'});
        
        
        %TODO: decice wheter this is a hack or feature. Allows to use
        %dv.trial before the first trial. But it's a Params class
        %until the first trial starts
        dv.trial = dv.defaultParameters; 
    end 
     
    function dv = runTrial(dv)
    % [PDS,dv] = runTrial(dv,PDS)
    % runs a single trial
    %
    % 03/2013 jly   Wrote hyperflow
    % 03/2014 jk    removed the hyper, added awesome. Used jly's code to get
    % the PLDAPS structure and frame it into a class
    % might change to ASYNC buffer flipping. but won't for now.

    %ok, what are the options?
    %we'll make them states
    %is called once after the last frame is done (or even before)
    %get current eyepostion, curser position or keypresses 
    dv.trial.pldaps.frameStates.frameUpdate=1;
    %here you can prepare all drawing, e.g. have the dots move
    %if you need to update to the latest e.g. eyeposition
    %you can still do that later, this could be all expected heavy
    %calculations
    dv.trial.pldaps.frameStates.framePrepareDrawing=2; 
    %once you know you've calculated the final image, draw it
    dv.trial.pldaps.frameStates.frameDraw=3;
    %
    dv.trial.pldaps.frameStates.frameIdlePreLastDraw=4;
    %if there is something that needs updating. here is a fucntion to do it
    %as late as possible
    dv.trial.pldaps.frameStates.frameDrawTimecritical=5;
    %if this function is not used, drawingFinished will be called after
    %frameDraw is done, otherwise drawingFinished will not be called
    dv.trial.pldaps.frameStates.frameDrawingFinished=6;

    %this function gets called once everything got drawn, until it's time
    %to expect (and do) the flip
    dv.trial.pldaps.frameStates.frameIdlePostDraw=7;
    %do the flip (or when async) record the time 
    dv.trial.pldaps.frameStates.frameFlip=8;
    
    dv.trial.currentFrameState=1;    
    
    trialSetup(dv);
    
    timeNeeded(dv.trial.pldaps.frameStates.frameUpdate)=0.5;
    timeNeeded(dv.trial.pldaps.frameStates.framePrepareDrawing)=2;
    timeNeeded(dv.trial.pldaps.frameStates.frameDraw)=2;
    timeNeeded(dv.trial.pldaps.frameStates.frameIdlePreLastDraw)=2;
    timeNeeded(dv.trial.pldaps.frameStates.frameDrawTimecritical)=0.5;
    timeNeeded(dv.trial.pldaps.frameStates.frameDrawingFinished)=2;
    timeNeeded(dv.trial.pldaps.frameStates.frameIdlePostDraw)=0.5;
    timeNeeded(dv.trial.pldaps.frameStates.frameFlip)=5;
    timeNeeded=timeNeeded/1000;%convert to seconds

    %will be called just before the trial starts for time critical calls to
    %start data aquisition
    trialPrepare(dv);



    dv.trial.framePreLastDrawIdleCount=0;
    dv.trial.framePostLastDrawIdleCount=0;


    dv.trial.prevFrameState=dv.trial.currentFrameState;
    dv.trial.prevTimeLastFrame=dv.trial.stimulus.timeLastFrame;
    dv.trial.prevFrame=dv.trial.iFrame;

    % pdsEyelinkGetQueue(dv);
    %%% MAIN WHILE LOOP %%%
    %-------------------------------------------------------------------------%
        while ~dv.trial.flagNextTrial && dv.trial.pldaps.quit == 0

            % update trial time
            dv.trial.ttime = GetSecs - dv.trial.trstart;

            %time of the estimated next flip
            nextFrameTime = dv.trial.stimulus.timeLastFrame+dv.trial.display.ifi;

            remainingTime=nextFrameTime-dv.trial.ttime;

            if(dv.trial.prevFrameState~=dv.trial.currentFrameState)
                    dv.trial.timing.frameStateChangeTimes(dv.trial.prevFrameState,dv.trial.prevFrame)=dv.trial.ttime-dv.trial.prevTimeLastFrame;
                    dv.trial.prevFrameState=dv.trial.currentFrameState;
                    dv.trial.prevTimeLastFrame=dv.trial.stimulus.timeLastFrame;
                    dv.trial.prevFrame=dv.trial.iFrame;
            end

            switch dv.trial.currentFrameState
                case dv.trial.pldaps.frameStates.frameUpdate
                    frameUpdate(dv);
                    dv.trial.currentFrameState = dv.trial.pldaps.frameStates.framePrepareDrawing;

                case dv.trial.pldaps.frameStates.framePrepareDrawing
                    framePrepareDrawing(dv);
                    dv.trial.currentFrameState = dv.trial.pldaps.frameStates.frameDraw;

                case dv.trial.pldaps.frameStates.frameDraw
                    frameDraw(dv);
                    dv.trial.currentFrameState=dv.trial.pldaps.frameStates.frameIdlePreLastDraw;
 
                case dv.trial.pldaps.frameStates.frameIdlePreLastDraw
                    frameIdlePreLastDraw(dv);

                    if(remainingTime<sum(timeNeeded(dv.trial.pldaps.frameStates.frameIdlePreLastDraw+1:end)))
                        dv.trial.currentFrameState=dv.trial.pldaps.frameStates.frameDrawTimecritical;
                    end
                    dv.trial.framePreLastDrawIdleCount = dv.trial.framePreLastDrawIdleCount +1;

                case dv.trial.pldaps.frameStates.frameDrawTimecritical
                    drawTimecritical(dv);
                    dv.trial.currentFrameState = dv.trial.pldaps.frameStates.frameDrawingFinished;
                     
                case dv.trial.pldaps.frameStates.frameDrawingFinished
                    %%(ifthere is sufficient time till the next expected Flip, call
                    %%drawingFinished
                    %%in this case we can also make an asyncBufferswap, i.e. we can
                    %%use the till till the flip to prepare the next frame.
                    %%we could probably alsways do this (async). If there is no
                    %%time left, we won't benefit that much, but it shoudn't hurt.
                    frameDrawingFinished(dv);
                    dv.trial.currentFrameState=dv.trial.pldaps.frameStates.frameIdlePostDraw;

                case dv.trial.pldaps.frameStates.frameIdlePostDraw
                    frameIdlePostDraw(dv);

                    if(remainingTime<sum(timeNeeded(dv.trial.pldaps.frameStates.frameIdlePostDraw+1:end)))
                        dv.trial.currentFrameState=dv.trial.pldaps.frameStates.frameFlip;
                    end
                    dv.trial.framePostLastDrawIdleCount = dv.trial.framePostLastDrawIdleCount +1;

                case dv.trial.pldaps.frameStates.frameFlip
                    frameFlip(dv);
                    %advance to next frame
                    dv.trial.currentFrameState=dv.trial.pldaps.frameStates.frameUpdate;

            end

        end %while Trial running

        dv.trial.ttime = GetSecs - dv.trial.trstart;
        if(dv.trial.prevFrameState~=dv.trial.currentFrameState)
            dv.trial.timing.frameStateChangeTimes(dv.trial.prevFrameState,dv.trial.prevFrame)=dv.trial.ttime-dv.trial.prevTimeLastFrame;
            dv.trial.prevFrameState=dv.trial.currentFrameState;
            dv.trial.prevTimeLastFrame=dv.trial.stimulus.timeLastFrame;
            dv.trial.prevFrame=dv.trial.iFrame;
        end

        dv = cleanUpandSave(dv);

    end %runTrial

    %%% get inputs and check behavior%%%
%---------------------------------------------------------------------% 
    function frameUpdate(dv)   
        %%TODO: add buffer for Keyboard presses, nouse position and clicks.
        
        %Keyboard    
        [dv.trial.keyboard.pressedQ,  dv.trial.keyboard.firstPressQ]=KbQueueCheck(); % fast
        if  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.mKey)
            if dv.trial.datapixx.use
                pdsDatapixxAnalogOut(dv.trial.stimulus.rewardTime)
                pdsDatapixxFlipBit(dv.trial.pldaps.events);
            end
            dv.trial.ttime = GetSecs - dv.trial.trstart;
            dv.trial.timeReward(dv.trial.iReward) = dv.trial.ttime;
            dv.trial.iReward = dv.trial.iReward + 1;
            PsychPortAudio('Start', dv.pa.sound.reward);
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
%             breakpoints=dbstatus('-completenames');
            dbstop if warning opticflow:debugger_requested;
            warning on opticflow:debugger_requested;
            warning('opticflow:debugger_requested','At your service!');
            warning off opticflow:debugger_requested;
            dbclear if warning opticflow:debugger_requested;
%             dbstop(breakpoints);
        end   
        % get mouse/eyetracker data
        [dv.trial.cursorX,dv.trial.cursorY,dv.trial.isMouseButtonDown] = GetMouse(); % ktz - added isMouseButtonDown, 28Mar2013
        %get eyeposition
        pdsGetEyePosition(dv, true);
    end %frameUpdate
% 
    function framePrepareDrawing(dv)
    end %framePrepareDrawing

    %% frameDraw
    function frameDraw(dv)
        %this could hold the code to draw some stuff to the overlay (using
        %switches, like the grid, the eye Position, etc
        
        %consider moving this stuff to an earlier timepoint, to allow GPU
        %to crunch on this before the real stuff gets added.
        if dv.trial.pldaps.draw.grid.use
            Screen('DrawLines',dv.trial.display.overlayptr,dv.trial.pldaps.draw.grid.tick_line_matrix,1,5,dv.trial.display.ctr(1:2))
        end
        
         %draw the eyepositon to the second srceen only
         %move the color and size parameters to
         %dv.trial.pldaps.draw.eyepos?
         if dv.trial.pldaps.draw.eyepos.use
            Screen('Drawdots',  dv.trial.display.overlayptr, [dv.trial.eyeX dv.trial.eyeY]', ...
            dv.trial.stimulus.eyeW, dv.trial.stimulus.colorEyeDot*[1 1 1]', dv.trial.display.ctr(1:2),0)
         end
         
         if dv.trial.pldaps.draw.photodiode.use && mod(dv.trial.iFrame, dv.trial.pldaps.draw.photodiode.everyXFrames) == 0
            photodiodecolor = dv.trial.display.clut.window;
            dv.trial.timing.photodiodeTimes(:,dv.trial.pldaps.draw.photodiode.dataEnd) = [dv.trial.ttime dv.trial.iFrame];
            dv.trial.pldaps.draw.photodiode.dataEnd=dv.trial.pldaps.draw.photodiode.dataEnd+1;
            Screen('FillRect',  dv.trial.display.overlayptr,photodiodecolor*ones(3,1), dv.trial.pldaps.draw.photodiode.rect')
        end
    end %frameDraw

    %% frameIdlePreLastDraw
    function frameIdlePreLastDraw(dv)
        %only execute once, since this is the only part atm, this is done at 0
        if dv.trial.framePreLastDrawIdleCount==0    
        else %if no one stepped in to execute we might as well skip to the next stage
            dv.trial.currentFrameState=dv.trial.pldaps.frameStates.frameDrawTimecritical;
        end
    end %frameIdlePreLastDraw

    function drawTimecritical(dv)
    end %drawTimecritical

    function frameDrawingFinished(dv)
        Screen('DrawingFinished', dv.trial.display.ptr);
        Screen('DrawingFinished', dv.trial.display.overlayptr);
        %if we're going async, we'd probably do the flip call here, right? but
        %could also do it in the flip either way.
    end %frameDrawingFinished

    function frameIdlePostDraw(dv)
        if dv.trial.framePostLastDrawIdleCount==0  
        else
            dv.trial.currentFrameState=dv.trial.pldaps.frameStates.frameFlip;
        end
    end %frameIdlePostDraw

    function frameFlip(dv)
        [dv.trial.timing.flipTimes(3,dv.trial.iFrame), dv.trial.timing.flipTimes(4,dv.trial.iFrame), dv.trial.timing.flipTimes(1,dv.trial.iFrame), dv.trial.timing.flipTimes(2,dv.trial.iFrame)] = Screen('Flip', dv.trial.display.ptr,0); %#ok<ASGLU>
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

            dv.trial.stimulus.timeLastFrame = dv.trial.timing.flipTimes(1,dv.trial.iFrame)-dv.trial.trstart;
            dv.trial.framePreLastDrawIdleCount=0;
            dv.trial.framePostLastDrawIdleCount=0;
            dv.trial.iFrame = dv.trial.iFrame + 1;  % update frame index
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
        pdsAudioClearBuffer(dv)


        if dv.trial.datapixx.use
            Datapixx RegWrRd;
        end
        


        %%% Initalize Keyboard %%%
        %-------------------------------------------------------------------------%
        pdsKeyboardClearBuffer(dv);

        %%% Spike server
        %-------------------------------------------------------------------------%
        [dv,spikes] = pdsSpikeserverGetSpikes(dv); %what are we dowing with the spikes???

        %%% Eyelink Toolbox Setup %%%
        %-------------------------------------------------------------------------%
        % preallocate for all eye samples and event data from the eyelink
        pdsEyelinkStartTrial(dv);


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
                pdsDatapixxStrobe(clocktime(ii));
            end
        end
        dv.trial.unique_number = clocktime;    % trial identifier
        [ig, ig, dv.trial.lastFrameTime] = Screen('Flip', dv.trial.display.ptr,0); %#ok<ASGLU>
        dv.trial.trstart = GetSecs;

        if dv.trial.datapixx.use
            dv.trial.timing.datapixxStartTime = Datapixx('Gettime');
            pdsDatapixxFlipBit(dv.trial.event.TRIALSTART);  % start of trial (Plexon)
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

        [dv.trial.timing.flipTimes(3,dv.trial.iFrame), dv.trial.timing.flipTimes(4,dv.trial.iFrame), dv.trial.timing.flipTimes(1,dv.trial.iFrame), dv.trial.timing.flipTimes(2,dv.trial.iFrame)] = Screen('Flip', dv.trial.display.ptr); %#ok<ASGLU>

        if(dv.trial.pldaps.draw.photodiode.use)
            dv.trial.timing.photodiodeTimes(:,dv.trial.pldaps.draw.photodiode.dataEnd:end)=[];
        end
        % if isfield(dv, 'dp') % FIX ME
        %     dv.dp = pdsDatapixxAdcStop(dv.dp);
        % end

        %% Flush KbQueue %%%
        KbQueueStop();
        KbQueueFlush();


        % Get spike server spikes
        %---------------------------------------------------------------------%
        if isfield(dv.trial, 'spikeserver') && dv.trial.spikeserver.use
            try
                [dv, dv.trial.spikeserver.spikes] = pdsSpikeServerGetSpikes(dv);

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
        dv.trial.timing.ptbFliptimes       = dv.trial.timing.flipTimes(:,1:dv.trial.iFrame);
        dv.trial.timing.flipTimes      = dv.trial.timing.flipTimes(:,1:dv.trial.iFrame);
        dv.trial.timing.frameStateChangeTimes    = dv.trial.timing.frameStateChangeTimes(:,1:dv.trial.iFrame-1);

        % if isfield(dv, 'dp') % FIX ME
        %     analogTime = linspace(dv.dp.adctstart, dv.dp.adctend, size(dv.dp.bufferData,2));
        %     PDS.data.datapixxAnalog{dv.j} = [analogTime(:) dv.dp.bufferData'];
        % end
      
        if dv.trial.eyelink.use
            [Q, rowId] = pdsEyelinkSaveQueue(dv);
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
    
 end %methods


end