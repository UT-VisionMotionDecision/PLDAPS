function p = run(p)
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

% try
    %% Setup and File management
    % clean IOPort handles (no PTB method to retrieve previously opened IOPort handles, so might as well clean slate)
    IOPort('CloseAll');
    
    % Enure we have an experimentSetupFile set and verify output file
    
    %make sure we are not running an experiment twice
    if isField(p.defaultParameters, 'session.initTime')
        warning('pldaps:run', 'pldaps objects appears to have been run before. A new pldaps object is needed for each run');
        return
    else
        p.defaultParameters.session.initTime=now;
    end
        
    if ~p.defaultParameters.pldaps.nosave
        p.defaultParameters.session.dir = p.defaultParameters.pldaps.dirs.data;
        p.defaultParameters.session.file = [p.defaultParameters.session.subject datestr(p.defaultParameters.session.initTime, 'yyyymmdd') p.defaultParameters.session.experimentSetupFile datestr(p.defaultParameters.session.initTime, 'HHMM') '.PDS'];
%         p.defaultParameters.session.file = fullfile(p.defaultParameters.pldaps.dirs.data, [p.defaultParameters.session.subject datestr(p.defaultParameters.session.initTime, 'yyyymmdd') p.defaultParameters.session.experimentSetupFile datestr(p.defaultParameters.session.initTime, 'HHMM') '.PDS']);
        
        if p.defaultParameters.pldaps.useFileGUI
            [cfile, cdir] = uiputfile('.PDS', 'specify data storage file', fullfile( p.defaultParameters.session.dir,  p.defaultParameters.session.file));
            if(isnumeric(cfile)) %got canceled
                error('pldaps:run','file selection canceled. Not sure what the correct default bevaior would be, so stopping the experiment.')
            end
            p.defaultParameters.session.dir = cdir;
            p.defaultParameters.session.file = cfile;
        end

         if ~exist(p.trial.session.dir, 'dir')
            warning('pldaps:run','Data directory specified in .pldaps.dirs.data does not exist. Quitting PLDAPS. p.trial.pldaps.dirs.data=%s\nPlease create the directory along with a subdirectory called TEMP',p.trial.session.dir);
            return;
         end
    else
        p.defaultParameters.session.file='';
        p.defaultParameters.session.dir='';
    end

    if p.trial.pldaps.useModularStateFunctions
        %experimentSetup before openScreen to allow modifyiers
        [modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
        runStateforModules(p,'experimentPreOpenScreen',modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
    end
    
    %% Open PLDAPS windows
    % Open PsychToolbox Screen
    p = openScreen(p);
    
    % Setup PLDAPS experiment condition
    p.defaultParameters.pldaps.maxFrames=p.defaultParameters.pldaps.maxTrialLength*p.defaultParameters.display.frate;

    if ~isempty(p.defaultParameters.session.experimentSetupFile)
        feval(p.defaultParameters.session.experimentSetupFile, p);
    end
    
            %
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
        
    
    
    %now setup everything for the first trial
   
%     p.defaultParameters.pldaps.iTrial=trialNr;
    
    %we'll have a trialNr counter that the trial function can tamper with?
    %do we need to lock the defaultParameters to prevent tampering there?
    levelsPreTrials=p.defaultParameters.getAllLevels();
%     p.defaultParameters.addLevels(p.conditions(trialNr), {['Trial' num2str(trialNr) 'Parameters']});
    
    %for now all structs will be in the parameters class, first
    %levelsPreTrials, then we'll add the condition struct before each trial.
%     p.defaultParameters.setLevels([levelsPreTrials length(levelsPreTrials)+trialNr])
%     p.defaultParameters.pldaps.iTrial=trialNr;
%     p.trial=mergeToSingleStruct(p.defaultParameters);
    
    %only use p.trial from here on!
    
    %% main trial loop %%
    while p.trial.pldaps.iTrial < p.trial.pldaps.finish && p.trial.pldaps.quit~=2
        
        if p.trial.pldaps.quit == 0
            
           %load parameters for next trial and lock defaultsParameters
           trialNr=trialNr+1;
           if ~isempty(p.conditions)
            p.defaultParameters.addLevels(p.conditions(trialNr), {['Trial' num2str(trialNr) 'Parameters']});
            p.defaultParameters.setLevels([levelsPreTrials length(levelsPreTrials)+trialNr]);
           else
            p.defaultParameters.setLevels([levelsPreTrials]);
           end
           p.defaultParameters.pldaps.iTrial=trialNr;
           

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
            

           p.defaultParameters.setLock(true);
            
           % run trial
           p = feval(p.trial.pldaps.trialMasterFunction,  p);
            
           %unlock the defaultParameters
           p.defaultParameters.setLock(false); 
            
           %save tmp data
           result = saveTempFile(p); 
           if ~isempty(result)
               disp(result.message)
           end
                      
           if p.defaultParameters.pldaps.save.mergedData
               %store the complete trial struct to .data
               dTrialStruct = p.trial;
           else
               %store the difference of the trial struct to .data
               dTrialStruct=getDifferenceFromStruct(p.defaultParameters,p.trial);
           end
           p.data{trialNr}=dTrialStruct;
           
           
           if p.trial.pldaps.useModularStateFunctions
               oldptrial=p.trial;
               [modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
               p.defaultParameters.setLevels(levelsPreTrials);
               p.defaultParameters.pldaps.iTrial=trialNr;
               p.trial=mergeToSingleStruct(p.defaultParameters);
               p.defaultParameters.setLock(true); 

               runStateforModules(p,'experimentAfterTrials',modulesNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);

               p.defaultParameters.setLock(false); 
               betweenTrialsStruct=getDifferenceFromStruct(p.defaultParameters,p.trial);
               if(~isequal(struct,betweenTrialsStruct))
                    p.defaultParameters.addLevels({betweenTrialsStruct}, {['experimentAfterTrials' num2str(trialNr) 'Parameters']});
                    levelsPreTrials=[levelsPreTrials length(p.defaultParameters.getAllLevels())]; %#ok<AGROW>
               end

               p.trial=oldptrial;
           end

           %advance to next trial
%            if(p.trial.pldaps.iTrial ~= p.trial.pldaps.finish)
%                 %now we add this and the next Trials condition parameters
%                 p.defaultParameters.addLevels(p.conditions(trialNr), {['Trial' num2str(trialNr) 'Parameters']},[levelsPreTrials length(levelsPreTrials)+trialNr]);
%                 p.defaultParameters.pldaps.iTrial=trialNr;
%                 p.trial=mergeToSingleStruct(p.defaultParameters);
%            else
%                 p.trial.pldaps.iTrial=trialNr;
%            end
%            
%            if isfield(dTrialStruct,'pldaps')
%                if isfield(dTrialStruct.pldaps,'finish') 
%                     p.trial.pldaps.finish=dTrialStruct.pldaps.finish;
%                end
%                if isfield(dTrialStruct.pldaps,'quit') 
%                     p.trial.pldaps.quit=dTrialStruct.pldaps.quit;
%                end
%            end
            
        else %dbquit ==1 is meant to be pause. should we halt eyelink, datapixx, etc?
            %create a new level to store all changes in, 
            %load only non trial paraeters
            pause=p.trial.pldaps.pause.type;
            p.trial=p.defaultParameters;
            
            p.defaultParameters.addLevels({struct}, {['PauseAfterTrial' num2str(trialNr) 'Parameters']});
            p.defaultParameters.setLevels([levelsPreTrials length(p.defaultParameters.getAllLevels())]);
            
            if pause==1 %0=don't,1 is debugger, 2=pause loop
                ListenChar(0);
                ShowCursor;
                p.trial
                disp('Ready to begin trials. Type return to start first trial...')
                keyboard %#ok<MCKBD>
                p.trial.pldaps.quit = 0;
                ListenChar(2);
                HideCursor;
            elseif pause==2
                pauseLoop(p);
            end           
%             pds.datapixx.refresh(p);

            %now I'm assuming that nobody created new levels,
            %but I guess when you know how to do that
            %you should also now how to not skrew things up
            allStructs=p.defaultParameters.getAllStructs();
            if(~isequal(struct,allStructs{end}))
                levelsPreTrials=[levelsPreTrials length(allStructs)]; %#ok<AGROW>
            end
        end
        
    end
    
    %make the session parameterStruct active
    p.defaultParameters.setLevels(levelsPreTrials);
    p.trial = p.defaultParameters;
    
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
    
    if ~p.defaultParameters.pldaps.nosave
        [structs,structNames] = p.defaultParameters.getAllStructs();
        
        PDS=struct;
        PDS.initialParameters=structs(levelsPreTrials);
        PDS.initialParameterNames=structNames(levelsPreTrials);
        if p.defaultParameters.pldaps.save.initialParametersMerged
            PDS.initialParametersMerged=mergeToSingleStruct(p.defaultParameters); %too redundant?
        end
        
        levelsCondition=1:length(structs);
        levelsCondition(ismember(levelsCondition,levelsPreTrials))=[];
        PDS.conditions=structs(levelsCondition);
        PDS.conditionNames=structNames(levelsCondition);
        PDS.data=p.data; 
        PDS.functionHandles=p.functionHandles;
        if p.defaultParameters.pldaps.save.v73
            save(fullfile(p.defaultParameters.session.dir, p.defaultParameters.session.file),'PDS','-mat','-v7.3')
        else
            save(fullfile(p.defaultParameters.session.dir, p.defaultParameters.session.file),'PDS','-mat')
        end
    end
    

    if p.trial.display.movie.create
        Screen('FinalizeMovie', p.trial.display.movie.ptr);
    end
    
    if p.defaultParameters.display.useOverlay==2
        glDeleteTextures(2,p.trial.display.lookupstexs(1));
    end
    Screen('CloseAll');

    sca;
    
% catch me
%     if p.trial.eyelink.use
%        pds.eyelink.finish(p); 
%     end
%     sca
%     if p.trial.sound.use
%         PsychPortAudio('Close')
%     end
%     % return cursor and command-line control
%     ShowCursor
%     ListenChar(0)
%     disp(me.message)
%     
%     nErr = size(me.stack); 
%     for iErr = 1:nErr
%         fprintf('errors in %s line %d\r', me.stack(iErr).name, me.stack(iErr).line)
%     end
%     fprintf('\r\r')
%     keyboard    
% end

end
%we are pausing, will create a new defaultParaneters Level where changes
%would go.
function pauseLoop(p)
        ShowCursor;
%         ListenChar(1); % is this necessary
        KbQueueRelease();
        KbQueueCreate();
        KbQueueStart();
        altLastPressed=0;
        ctrlLastPressed=0;
        ctrlPressed=false;
        altPressed=false;
        
        while p.trial.pldaps.quit==1
            %the keyboard chechking we only capture ctrl+alt key presses.
            [p.trial.keyboard.pressedQ,  p.trial.keyboard.firstPressQ]=KbQueueCheck(); % fast
            if p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.Lctrl)&&p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.Lalt)
                %D: Debugger
                if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.dKey) 
                    disp('stepped into debugger. Type return to start first trial...')
                    keyboard %#ok<MCKBD>

                %E: Eyetracker Setup
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.eKey)
                    try
                       if(p.trial.eyelink.use) 
                           pds.eyelink.calibrate(p);
                       end
                    catch ME
                        display(ME);
                    end

                %M: Manual reward
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.mKey)
                    pds.behavior.reward.give(p);
%                     if p.trial.datapixx.use
%                         pds.datapixx.analogOut(p.trial.stimulus.rewardTime)
%                         pds.datapixx.flipBit(p.trial.event.REWARD);
%                     end
%                     p.trial.ttime = GetSecs - p.trial.trstart;
%                     p.trial.stimulus.timeReward(:,p.trial.iReward) = [p.trial.ttime p.trial.stimulus.rewardTime];
%                     p.trial.stimulus.iReward = p.trial.iReward + 1;
%                     PsychPortAudio('Start', p.trial.sound.reward);

                %P: PAUSE (end the pause) 
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.pKey)
                    p.trial.pldaps.quit = 0;
                    ListenChar(2);
                    HideCursor;
                    break;

                %Q: QUIT
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.qKey)
                    p.trial.pldaps.quit = 2;
                    break;
                
                %X: Execute text selected in Matlab editor
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.xKey)
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
