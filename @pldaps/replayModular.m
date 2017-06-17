function p = replayModular2(p,input)
% % PDS.initialParameters{4}.stimulus.showFixationPoint=true;
% % PDS.initialParameters{4}.stimulus.fixdotW=5
% settingsStruct.display.movie.frameRate=30;
% settingsStruct.display.movie.create=1;
% settingsStruct.display.movie.options=':CodecType=VideoCodec=x264enc speed-preset=1 noise-reduction=000000 Videobitrate=32768';
% settingsStruct.display.useOverlay=2;
% settingsStruct.display.switchOverlayCLUTs=false;
% settingsStruct.display.bgColor=PDS.initialParametersMerged.display.bgColor;
% settingsStruct.display.screenSize = 100+[0 0 1920/2 1080/2];
% settingsStruct.display.screenSize = 100+[0 0 1920 1080/2];
% settingsStruct.display.screenSize = 100+[0 0 1920*2 1080];
% settingsStruct.openephys.use=false;
% settingsStruct.newEraSyringePump.use=false;
% settingsStruct.nan.use=false;
% settingsStruct.eyemarker.use=false;
% settingsStruct.eyemarker.stateFunction.requestedStates.frameReplayUpdate=true;
% settingsStruct.eyemarker.stateFunction.requestedStates.trialReplaySetup=true;
% settingsStruct.mouse.use=false;
% settingsStruct.plot.use=false;
% settingsStruct.replay.eyeXYs = 2;
%run    run a new experiment for a previuously created pldaps class
% p = run(p)
% PLDAPS (Plexon Datapixx PsychToolbox) version 4.1
%       run is a wrapper for calling PLDAPS package files
%           It opens the PsychImaging pipeline and initializes datapixx for
%           dual color lookup tables. 
% 10/2011 jly wrote it (modified from letsgorun.m)
% 12/2013 jly reboot. updated to version 3 format.
% 04/2014 jk  moved into a pldaps class; adapated to new class structure

%TODO: 
% one unified system for modules, e.g. moduleSetup, moduleUpdate, moduleClose
% make HideCursor optional
% TODO:reset class at end of experiment or mark as recorded, so I don't
% run the same again by mistake
if ischar(input)
    load(input,'-mat');
else
    PDS=input;
end

setLevels(p.trial, 1)
defaults=mergeToSingleStruct(p.trial);
setLevels(p.trial, 2:4)
inparms=mergeToSingleStruct(p.trial);
setLevels(p.trial, 1:4);

PDS.initialParameters{4}.display=rmfield(PDS.initialParameters{4}.display,'info'); 

PDS.initialParameters = {defaults PDS.initialParameters{1:4} inparms PDS.initialParameters{5:end} struct};
PDS.initialParameterNames = {'replayDefaults' PDS.initialParameterNames{1:4} 'replaySettings' PDS.initialParameterNames{5:end} 'withinReplaySettings'};

% ok, recareate the _input_ parameters that pldaps saw.
% remove data form PDS struct for that
[pa, trialLevelMatrix, nTrials] = recreateParams(rmfield(PDS,'data'));

%this will override all parameters before. probabbly not a good longterm
%idea.
newDisplay=p.trial.display;
newparams=p.trial;

% p.defaultParameters=params([initialParameters PDS.conditions],[initialParameterNames PDS.conditionNames]);
p.defaultParameters=pa;
p.trial=p.defaultParameters;
p.conditions=PDS.conditions';

%the level that are valid for all trials are those that were valid in the
%beginning.
p.defaultParameters.setLevels(all(trialLevelMatrix,2));

   p.defaultParameters.datapixx.use=false;
    p.defaultParameters.sound.flagBuzzer=0;
    p.defaultParameters.sound.use=1;
    p.defaultParameters.plexon.spikeserver.use = 0;
    p.defaultParameters.eyelink.use = 0;
    p.defaultParameters.newEraSyringePump.use = false;
    
p.trial.pldaps.pause=newparams.pldaps.pause;
    
p.data=PDS.data;
% p.functionHandles=PDS.functionHandles;
% p.trial.postanalysis=PDS.postanalysis;
% 
% %todo aspect ratio
% if p.trial.display.screenSize ~= newDisplay.screenSize
%     p.trial.display.winRect(3:4)~= newDisplay.screenSize;
    
p.trial.display.screenSize=newDisplay.screenSize;
p.trial.display.scrnNum=newDisplay.scrnNum;
p.trial.display.useOverlay=newDisplay.useOverlay;
p.trial.display.colorclamp=newDisplay.colorclamp;
p.trial.display.forceLinearGamma=newDisplay.forceLinearGamma;
p.trial.display.movie=newDisplay.movie;
if isfield(newDisplay,'gamma')
    p.trial.display.gamma=newDisplay.gamma;
end
p.trial.display.bgColor=newDisplay.bgColor;

p.defaultParameters.pldaps.dirs=newparams.pldaps.dirs;

KbQueueReserve(1, 2,[])

% %%zoom in
% p.trial.display.widthcm=PDS.initialParametersMerged.display.widthcm/4;
% p.trial.display.heightcm=PDS.initialParametersMerged.display.heightcm/2;

% p.trial.mouse.useLocalCoordinates =false;
% p.trial.mouse.initialCoordinates = [];

p.trial.pldaps.trialStates.frameReplayUpdate=p.trial.pldaps.trialStates.frameUpdate;
p.trial.pldaps.trialStates.frameUpdate = -Inf;
p.trial.pldaps.trialStates.trialReplaySetup = p.trial.pldaps.trialStates.trialSetup - 0.5;

p.trial.session.dir = p.trial.pldaps.dirs.data;
try

%     if p.trial.pldaps.useModularStateFunctions
%         %experimentSetup before openScreen to allow modifyiers
%         [modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
%         runStateforModules(p,'experimentPreOpenScreen',modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
%     end
    
    %% Open PLDAPS windows
    % Open PsychToolbox Screen
    p = openScreen(p);

    %% cheats    
    p.trial.display.frate = PDS.initialParametersMerged.display.frate;
    p.trial.display.ifi = PDS.initialParametersMerged.display.ifi;
    allbg=repmat(PDS.initialParametersMerged.display.bgColor,size(p.trial.display.humanCLUT,1),1);
    newallbg=repmat(p.trial.display.bgColor,size(p.trial.display.humanCLUT,1),1);
    ci = find(all(p.trial.display.humanCLUT==allbg,2));
    p.trial.display.humanCLUT(ci,:)=newallbg(ci,:);
    ci = find(all(p.trial.display.monkeyCLUT==allbg,2));
    p.trial.display.monkeyCLUT(ci,:)=newallbg(ci,:);
    % rescale dot drawing
    p.trial.replay.xfactor= p.trial.display.pWidth/PDS.initialParametersMerged.display.pWidth;
    p.trial.replay.yfactor= p.trial.display.pHeight/PDS.initialParametersMerged.display.pHeight;
    
%     oldA=p.trial.(sn).allobjects;
%     A=loadMarmieFaces(p);
    p.trial.replay.stimulus.allobjects=loadMarmieFaces(p);
    if ~isfield(p.trial.stimulus, 'allobjects') && isfield(PDS.initialParametersMerged.stimulus, 'object')
       p.trial.stimulus.allobjects.tex=unique([PDS.initialParametersMerged.stimulus.object.texture]); 
    end
    p.trial.replay.display=PDS.initialParametersMerged.display;
%     p.trial.eyelink.calibration_matrix=p.trial.eyelink.calibration_matrix*0;
%     p.trial.eyelink.calibration_matrix(1,1,:)=1;
%     p.trial.eyelink.calibration_matrix(2,2,:)=1;
    
%     p.trial.replay.display.ptr=PDS.initialParametersMerged.display.ptr;
%     p.trial.replay.display.overlayptr=PDS.initialParametersMerged.display.overlayptr;
%     
    
    
    
 %%
            % Setup Photodiode stimuli
            %-------------------------------------------------------------------------%
            if(p.trial.pldaps.draw.photodiode.use)
                makePhotodiodeRect(p);
            end
    
            % Tick Marks
            %-------------------------------------------------------------------------%
            if(p.trial.pldaps.draw.grid.use)
                p = initTicks(p);
            end


            %get and store changes of current code to the git repository
            p = pds.git.setup(p);
            
            %things that were in the conditionFile
            p = pds.eyelink.setup(p);
    
            %things that where in the default Trial Structure
            
            % Audio
            %-------------------------------------------------------------------------%
            p = pds.audio.setup(p);
            
            % PLEXON
            %-------------------------------------------------------------------------%
            p = pds.plexon.spikeserver.connect(p);
            
            % REWARD
            %-------------------------------------------------------------------------%
            p = pds.behavior.reward.setup(p);
                     
            % Initialize Datapixx including dual CLUTS and timestamp
            % logging
            p = pds.datapixx.init(p);
            
            pds.keyboard.setup(p);

            if p.trial.mouse.useLocalCoordinates
                p.trial.mouse.windowPtr=p.trial.display.ptr;
            end
            if ~isempty(p.trial.mouse.initialCoordinates)
                SetMouse(p.trial.mouse.initialCoordinates(1),p.trial.mouse.initialCoordinates(2),p.trial.mouse.windowPtr)
            end
    
            if p.trial.pldaps.useModularStateFunctions
                [modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
                runStateforModules(p,'experimentPostOpenScreen',modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
            end

    %% Last chance to check variables
    if(p.trial.pldaps.pause.type==1 && p.trial.pldaps.pause.preExperiment==true) %0=don't,1 is debugger, 2=pause loop
        p  %#ok<NOPRT>
        disp('Ready to begin trials. Type return to start first trial...')
        keyboard %#ok<MCKBD>
    end
 
    %%%%start recoding on all controlled components this in not currently done here
    % save timing info from all controlled components (datapixx, eyelink, this pc)
    p = beginExperiment(p);

    % disable keyboard
    ListenChar(2)
    HideCursor
    
    p.trial.flagNextTrial  = 0; % flag for ending the trial
    p.trial.iFrame     = 1;  % frame index
    
    %save defaultParameters as trial 0
    trialNr=0;
    p.trial.pldaps.iTrial=0;
    p.trial=mergeToSingleStruct(p.defaultParameters);
    result = saveTempFile(p); 
    if ~isempty(result)
        disp(result.message)
    end
    
    
  
    %% main trial loop %%
    while p.trial.pldaps.iTrial < p.trial.pldaps.finish
        
%         if p.trial.pldaps.quit == 0
            
           %load parameters for next trial and lock defaultsParameters
           trialNr=trialNr+1;
           p.defaultParameters.setLevels(trialLevelMatrix(:,trialNr));
           p.defaultParameters.pldaps.iTrial=trialNr;
           p.defaultParameters.pldaps.quit = 0;

           %it looks like the trial struct gets really partitioned in
           %memory and this appears to make some get (!) calls slow. 
           %We thus need a deep copy. The superclass matlab.mixin.Copyable
           %is supposed to do that, but that is ver very slow, so we create 
           %a manual deep copy by saving the struct to a file and loading it 
           %back in.
           tmpts=mergeToSingleStruct(p.defaultParameters);
           save([p.trial.pldaps.dirs.data filesep 'TEMP' filesep 'deepTrialStruct'], 'tmpts');
           clear tmpts
           load([p.trial.pldaps.dirs.data filesep 'TEMP' filesep 'deepTrialStruct']);
           p.trial=tmpts;
           clear tmpts;
%             p.trial=mergeToSingleStruct(p.defaultParameters);
           p.trial.pldaps.finish=length(PDS.data);

           p.defaultParameters.setLock(true);
%            
%            if strcmp(p.trial.pldaps.trialFunction, 'gta.gta')
%                for iO=1:length(p.trial.stimulus.object)
%                   if p.trial.stimulus.object(iO).windowPtr==PDS.initialParametersMerged.display.ptr
%                       p.trial.stimulus.object(iO).windowPtr = p.trial.display.ptr;
%                   elseif p.trial.stimulus.object(iO).windowPtr==PDS.initialParametersMerged.display.overlayptr
%                       p.trial.stimulus.object(iO).windowPtr = p.trial.display.overlayptr;
%                   end
%                   if p.trial.stimulus.object(iO).type==2
%                      ti=find(oldA.tex==p.trial.stimulus.object(iO).texture);
%                      p.trial.stimulus.object(iO).texture = A.tex(ti);
%                      p.trial.stimulus.object(iO).stimRect(3:4) = A.texSizes(:,ti);
%                   end
%                   p.trial.mouse.use=false;
%                end
%            elseif strcmp(p.trial.pldaps.trialFunction, 'gta.gtb')
%                 iO=1;
%                 on=sprintf('object%i', iO);
%                 while isfield(p.trial.stimulus, on)
%                   if p.trial.stimulus.(on).windowPtr==PDS.initialParametersMerged.display.ptr
%                       p.trial.stimulus.(on).windowPtr = p.trial.display.ptr;
%                   elseif p.trial.stimulus.(on).windowPtr==PDS.initialParametersMerged.display.overlayptr
%                       p.trial.stimulus.(on).windowPtr = p.trial.display.overlayptr;
%                   end
%                   if p.trial.stimulus.(on).type==2
%                      ti=find(oldA.tex==p.trial.stimulus.(on).texture);
%                      p.trial.stimulus.(on).texture = A.tex(ti);
%                      p.trial.stimulus.(on).stimRect(3:4) = A.texSizes(:,ti);
%                   end
%                   p.trial.mouse.use=false;
%                   
%                   iO=iO+1;
%                   on=sprintf('object%i', iO);
%                end
%            end
%             
           % run trial
           runModularTrial(p, true)
%            p = feval(p.trial.pldaps.trialMasterFunction,  p);
            
           %unlock the defaultParameters
           p.defaultParameters.setLock(false); 
            
           %save tmp data
           result = saveTempFile(p); 
           if ~isempty(result)
               disp(result.message)
           end
                      
           if isfield(p.trial,'replay')
                p.data{trialNr}.replay=p.trial.replay;
           end
           
           
%            if p.trial.pldaps.useModularStateFunctions
%                oldptrial=p.trial;
%                [modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
%                p.defaultParameters.setLevels(levelsPreTrials);
%                p.defaultParameters.pldaps.iTrial=trialNr;
%                p.trial=mergeToSingleStruct(p.defaultParameters);
%                p.defaultParameters.setLock(true); 
% 
%                runStateforModules(p,'experimentAfterTrials',modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
% 
%                p.defaultParameters.setLock(false); 
%                betweenTrialsStruct=getDifferenceFromStruct(p.defaultParameters,p.trial);
%                if(~isequal(struct,betweenTrialsStruct))
%                     p.defaultParameters.addLevels({betweenTrialsStruct}, {['experimentAfterTrials' num2str(trialNr) 'Parameters']});
%                     levelsPreTrials=[levelsPreTrials length(p.defaultParameters.getAllLevels())]; %#ok<AGROW>
%                end
% 
%                p.trial=oldptrial;
%            end
           
           if ~p.defaultParameters.datapixx.use && p.defaultParameters.display.useOverlay
                glDeleteTextures(2,glGenTextures(1));
           end

            
%         else %dbquit ==1 is meant to be pause. should we halt eyelink, datapixx, etc?
%             %create a new level to store all changes in, 
%             %load only non trial paraeters
%             pause=p.trial.pldaps.pause.type;
%             p.trial=p.defaultParameters;
%             
%             p.defaultParameters.addLevels({struct}, {['PauseAfterTrial' num2str(trialNr) 'Parameters']});
%             p.defaultParameters.setLevels([levelsPreTrials length(p.defaultParameters.getAllLevels())]);
%             
%             if pause==1 %0=don't,1 is debugger, 2=pause loop
%                 ListenChar(0);
%                 ShowCursor;
%                 p.trial
%                 disp('Ready to begin trials. Type return to start first trial...')
%                 keyboard %#ok<MCKBD>
%                 p.trial.pldaps.quit = 0;
%                 ListenChar(2);
%                 HideCursor;
%             elseif pause==2
%                 pauseLoop(p);
%             end           
% %             pds.datapixx.refresh(dv);
% 
%             %now I'm assuming that nobody created new levels,
%             %but I guess when you know how to do that
%             %you should also now how to not skrew things up
%             allStructs=p.defaultParameters.getAllStructs();
%             if(~isequal(struct,allStructs{end}))
%                 levelsPreTrials=[levelsPreTrials length(allStructs)]; %#ok<AGROW>
%             end
%         end
        
    end
    
    %make the session parameterStruct active
    % return cursor and command-line control
    ShowCursor;
    ListenChar(0);
    Priority(0);
    
    p = pds.eyelink.finish(p);
    p = pds.plexon.finish(p);
    if(p.defaultParameters.datapixx.use)
        %start adc data collection if requested
        pds.datapixx.adc.stop(p);
        
        status = PsychDataPixx('GetStatus');
        if status.timestampLogCount
            p.defaultParameters.datapixx.timestamplog = PsychDataPixx('GetTimestampLog', 1);
        end
    end
    
    if p.defaultParameters.sound.use
        pds.audio.clearBuffer(p);
        % Close the audio device:
        PsychPortAudio('Close', p.defaultParameters.sound.master); 
    end
    
    if p.trial.pldaps.useModularStateFunctions
        [modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
        runStateforModules(p,'experimentCleanUp',modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
    end   

    if p.trial.display.movie.create
        Screen('FinalizeMovie', p.trial.display.movie.ptr);
    end
    
    if ~p.defaultParameters.datapixx.use && p.defaultParameters.display.useOverlay
        glDeleteTextures(2,glGenTextures(1));
    end
    Screen('CloseAll');

    sca;
    
catch me
    sca
    PsychPortAudio('Close')
    % return cursor and command-line control
    ShowCursor
    ListenChar(0)
    disp(me.message)
    
    nErr = size(me.stack); 
    for iErr = 1:nErr
        fprintf('errors in %s line %d\r', me.stack(iErr).name, me.stack(iErr).line)
    end
    fprintf('\r\r')
    keyboard    
end

end
%we are pausing, will create a new defaultParaneters Level where changes
%would go.
function pauseLoop(dv)
        ShowCursor;
        ListenChar(1);
        while(true)
            %the keyboard chechking we only capture ctrl+alt key presses.
            [dv.trial.keyboard.pressedQ,  dv.trial.keyboard.firstPressQ]=KbQueueCheck(); % fast
            if dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.Lctrl)&&dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.Lalt)
                %D: Debugger
                if  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.dKey) 
                    disp('stepped into debugger. Type return to start first trial...')
                    keyboard %#ok<MCKBD>

                %E: Eyetracker Setup
                elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.eKey)
                    try
                       if(dv.trial.eyelink.use) 
                           pds.eyelink.calibrate(dv);
                       end
                    catch ME
                        display(ME);
                    end

                %M: Manual reward
                elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.mKey)
                    pds.behavior.reward.give(p);
%                     if dv.trial.datapixx.use
%                         pds.datapixx.analogOut(dv.trial.stimulus.rewardTime)
%                         pds.datapixx.flipBit(dv.trial.event.REWARD);
%                     end
%                     dv.trial.ttime = GetSecs - dv.trial.trstart;
%                     dv.trial.stimulus.timeReward(:,dv.trial.iReward) = [dv.trial.ttime dv.trial.stimulus.rewardTime];
%                     dv.trial.stimulus.iReward = dv.trial.iReward + 1;
%                     PsychPortAudio('Start', dv.trial.sound.reward);

                %P: PAUSE (end the pause) 
                elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.pKey)
                    dv.trial.pldaps.quit = 0;
                    ListenChar(2);
                    HideCursor;
                    break;

                %Q: QUIT
                elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.qKey)
                    dv.trial.pldaps.quit = 2;
                    break;
                
                %X: Execute text selected in Matlab editor
                elseif  dv.trial.keyboard.firstPressQ(dv.trial.keyboard.codes.xKey)
                    activeEditor=matlab.desktop.editor.getActive; 
                    if isempty(activeEditor)
                        display('No Matlab editor open -> Nothing to execute');
                    else
                        if isempty(activeEditor.SelectedText)
                            display('Nothing selected in the active editor Widnow -> Nothing to execute');
                        else
                            try
                                eval(activeEditor.SelectedText)
                            catch ME
                                display(ME);
                            end
                        end
                    end
                    
                    
                end %IF CTRL+ALT PRESSED
            end
            pause(0.1);
        end

end
