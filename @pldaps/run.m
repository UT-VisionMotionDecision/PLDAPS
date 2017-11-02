function p = run(p)
%run    run a new experiment for a previuously created pldaps class
% p = run(p)
% PLDAPS (Plexon Datapixx PsychToolbox) version 4.2
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
    end
    
    p.defaultParameters.session.initTime=now;
    p.defaultParameters.pldaps.iTrial = 0; % necessary here to place iTrial counter in SessionParameters level of params hierarchy
        
    if ~p.defaultParameters.pldaps.nosave
        p.defaultParameters.session.dir = p.defaultParameters.pldaps.dirs.data;
        p.defaultParameters.session.file = sprintf('%s%s%s%s.PDS',...
                                                   p.defaultParameters.session.subject,...
                                                   datestr(p.defaultParameters.session.initTime, 'yyyymmdd'),...
                                                   p.defaultParameters.session.experimentSetupFile, ...
                                                   datestr(p.defaultParameters.session.initTime, 'HHMM'));
        
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

    
    %% experimentPreOpenScreen (...& modularPldaps setup)
    if p.trial.pldaps.useModularStateFunctions
        % Establish list of all module names
        p.trial.pldaps.modNames.all = getModules(p, 0);

        %experimentSetup before openScreen to allow modifyiers
        [moduleNames, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs] = getModules(p);        
        runStateforModules(p,'experimentPreOpenScreen', moduleNames, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs);
    end
    
    
    %% Open PLDAPS windows
    % Open PsychToolbox Screen
    p = openScreen(p);
    
    % Setup PLDAPS experiment condition
    p.defaultParameters.pldaps.maxFrames = p.defaultParameters.pldaps.maxTrialLength * p.defaultParameters.display.frate;


    %% experimentSetupFunction
    %   (i.e. fxn handle input w/ initial pldaps object creation)
    if ~isempty(p.defaultParameters.session.experimentSetupFile) && ~strcmp(p.defaultParameters.session.experimentSetupFile, 'none')
        feval(p.defaultParameters.session.experimentSetupFile, p);
    end
    
    
    %% Basic environment initialization
            
            % Setup Photodiode stimuli
            %-------------------------------------------------------------------------%
            if(p.trial.pldaps.draw.photodiode.use)
                makePhotodiodeRect(p);
            end
    
            % Tick Marks
            %-------------------------------------------------------------------------%
            if(p.trial.pldaps.draw.grid.use)
                initTicks(p);
            end

            % Codebase / version control
            %-------------------------------------------------------------------------%
            %get and store changes of current code to the git repository
            pds.git.setup(p);
            
            % Eye tracking
            %-------------------------------------------------------------------------%
            pds.eyelink.setup(p);
                
            % Audio
            %-------------------------------------------------------------------------%
            pds.audio.setup(p);
            
            % PLEXON
            %-------------------------------------------------------------------------%
            pds.plexon.spikeserver.connect(p);
            
            % REWARD
            %-------------------------------------------------------------------------%
            pds.behavior.reward.setup(p);
                     
            % Initialize Datapixx including dual CLUTS and timestamp
            % logging
            pds.datapixx.init(p);
            
            % HID
            pds.keyboard.setup(p);

            if p.trial.mouse.useLocalCoordinates
                p.trial.mouse.windowPtr=p.trial.display.ptr;
            end
            if ~isempty(p.trial.mouse.initialCoordinates)
                SetMouse(p.trial.mouse.initialCoordinates(1),p.trial.mouse.initialCoordinates(2),p.trial.mouse.windowPtr);
            end
    
            
        %% experimentPostOpenScreen
        if p.trial.pldaps.useModularStateFunctions
            [moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
            runStateforModules(p,'experimentPostOpenScreen',moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
        end

        
    %% Last chance to check variables
    if(p.trial.pldaps.pause.type==1 && p.trial.pldaps.pause.preExperiment==true) %0=don't,1 is debugger, 2=pause loop
        p  %#ok<NOPRT>
        disp('Ready to begin trials. Type "dbcont" to start first trial...')
        keyboard
    end
 
    
    %% Final preparations before trial loop begins
    %%%%start recoding on all controlled components this in not currently done here
    % save timing info from all controlled components (datapixx, eyelink, this pc)
    p = beginExperiment(p);

    % disable keyboard
    ListenChar(2);
    HideCursor;
    
    p.trial.flagNextTrial  = 0; % flag for ending the trial
    p.trial.iFrame     = 0;  % frame index
    
    % Save defaultParameters as trial 0
    % NOTE: the following line converts p.trial into a struct.
    % ------------------------------------------------
    % !!! Beyond this point, p.trial is NO LONGER A POINTER TO p.defaultParameters !!!
    % ------------------------------------------------
    p.trial=mergeToSingleStruct(p.defaultParameters);
    result = saveTempFile(p); 
    if ~isempty(result)
        disp(result.message)
    end
        
    %now setup everything for the first trial
    
    % we <will not> have a trialNr counter that the trial function can tamper with?
    % No apparent purpose to this...only invites danger of mismatched data outputs.
    
    % Record of baseline params class levels before start of experiment.
    % NOTE: "levelsPreTrials" --> "baseParamsLevels", since former was misnomer now
    %       that this var must be updated for everytime a non-trial parameters level
    %       is added (e.g. during every pause) --TBC 2017-10
    baseParamsLevels = p.defaultParameters.getAllLevels();  %#ok<*AGROW>
        
    
    %% Main trial loop
    while p.trial.pldaps.iTrial < p.trial.pldaps.finish && p.trial.pldaps.quit~=2
        
        if ~p.trial.pldaps.quit
            
           %load parameters for next trial and lock defaultsParameters
           nextTrial = p.defaultParameters.incrementTrial(+1);
           if ~isempty(p.conditions)
               p.defaultParameters.addLevels(p.conditions(nextTrial), {sprintf('Trial%dParameters', nextTrial)});
               p.defaultParameters.setLevels([baseParamsLevels length(baseParamsLevels)+nextTrial]);
           else
               p.defaultParameters.setLevels([baseParamsLevels]);
           end

           % ---------- p.defaultParameters >>to>> p.trial [struct!] ----------
           %it looks like the trial struct gets really partitioned in
           %memory and this appears to make some get (!) calls slow. 
           %We thus need a deep copy. The superclass matlab.mixin.Copyable
           %is supposed to do that, but that is ver very slow, so we create 
           %a manual deep copy by saving the struct to a file and loading it 
           %back in. --JK 2016(?)
           % Profiler suggests the overloaded subsref function of the params class
           % is a culprit; repeated "find" & "cellfun" calls in particular. Flipping
           % p.trial to a normal struct bypasses these overloaded class invocations.
           % There has to be a way to revise params class (particularly removing "find"
           % calls, which are known to be very slow), but have had little success at
           % deciphering the params.m code so far. --TBC 2017-10
           tmpts=mergeToSingleStruct(p.defaultParameters); %#ok<NASGU>
           save( fullfile(p.trial.pldaps.dirs.data, 'TEMP', 'deepTrialStruct'), '-struct', 'tmpts');
           clear tmpts
           p.trial = load(fullfile(p.trial.pldaps.dirs.data, 'TEMP', 'deepTrialStruct'));
%             p.trial=mergeToSingleStruct(p.defaultParameters);
            
           % Document currently active levels for this trial
           p.trial.pldaps.activeLevels = p.defaultParameters.getActiveLevels;

           % lock the defaultParameters structure
           p.defaultParameters.setLock(true);
            
           %---------------------------------------------------------------------% 
           % RUN THE TRIAL
           p = feval(p.trial.pldaps.trialMasterFunction,  p);
           %---------------------------------------------------------------------% 
            
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
               dTrialStruct = getDifferenceFromStruct(p.defaultParameters, p.trial);
           end
           p.data{p.defaultParameters.pldaps.iTrial} = dTrialStruct;
           
           % experimentAfterTrials  (Modular PLDAPS)
           if p.trial.pldaps.useModularStateFunctions && ~isempty(p.trial.pldaps.experimentAfterTrialsFunction)
               % Not clear what purpose this serves that could not be accomplished in trial cleanupandsave
               % and/or at start of next trial? ...open to suggestions. --TBC 2017-10
               oldptrial=p.trial;
               [moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
               p.defaultParameters.setLevels(baseParamsLevels);
               p.trial=mergeToSingleStruct(p.defaultParameters);
               p.defaultParameters.setLock(true); 
               runStateforModules(p,'experimentAfterTrials',moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);

               p.defaultParameters.setLock(false); 
               betweenTrialsStruct=getDifferenceFromStruct(p.defaultParameters,p.trial);
               if(~isequal(struct,betweenTrialsStruct))
                    p.defaultParameters.addLevels({betweenTrialsStruct}, {sprintf('experimentAfterTrials%dParameters', p.defaultParameters.pldaps.iTrial)});
                    baseParamsLevels=[baseParamsLevels length(p.defaultParameters.getAllLevels())];
               end

               p.trial=oldptrial;
           end

        else
            
            % Pause experiment. should we halt eyelink, datapixx, etc?
            ptype=p.trial.pldaps.pause.type;
                        
            % p.trial is once again a pointer after the following call (!)
            p.trial=p.defaultParameters; % NOTE: This step also resets the .pldaps.quit~=0 that triggered execution of this block
            
            % This will ALWAYS create a new 'level' (even if nothing is changed during pause)
            % ...doesn't seem to be the original intention, but allows changes during pause to be carried
            % over without overwriting prior settings, or getting lost in .conditions parameters. --TBC 2017-10
            p.defaultParameters.addLevels({struct}, {sprintf('PauseAfterTrial%dParameters', p.defaultParameters.pldaps.iTrial)});
            % include this new level in the list of baseline hierarchy levels.
            baseParamsLevels = [baseParamsLevels length(p.defaultParameters.getAllLevels())];
            % set baseline levels active (NOTE:  disables all trial-specific levels/params in the process)
            p.defaultParameters.setLevels(baseParamsLevels);
            
            if ptype==1 %0=don't,1 is debugger, 2=pause loop
                ListenChar(0);
                ShowCursor;
                p.trial
                disp('Experiment paused. Type "dbcont" to continue...')
                keyboard %#ok<MCKBD>
                ListenChar(2);
                HideCursor;
            elseif ptype==2
                pauseLoop(p);
            end           
%             pds.datapixx.refresh(p);

            %now I'm assuming that nobody created new levels,
            %but I guess when you know how to do that
            %you should also now how to not skrew things up
            allStructs=p.defaultParameters.getAllStructs();
            if(~isequal(struct,allStructs{end}))
                baseParamsLevels=[baseParamsLevels length(allStructs)];
            end
        end
        
    end
    
    %% Clean up & bookkeeping post-trial execution loop
    
    %make the session parameterStruct active
    % NOTE: This potentially obscures hierarchy levels (i.e. "PauseAfterTrial##Parameters") that
    %       are likely inconsistent throughout session. ...each trial data now includes a list
    %       of active hierarchy levels in .pldaps.activeLevels. --TBC 2017-10
    p.defaultParameters.setLevels(baseParamsLevels);
    p.trial = p.defaultParameters;
    
    % return cursor and command-line control
    ShowCursor;
    ListenChar(0);
    Priority(0);
    
    pds.eyelink.finish(p);  % p =  ; These should be operating on pldaps class handles, thus no need for outputs. --tbc.
    pds.plexon.finish(p);
    if(p.defaultParameters.datapixx.use)
        % stop adc data collection
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
        [moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
        runStateforModules(p,'experimentCleanUp',moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
    end
    
    if ~p.defaultParameters.pldaps.nosave
        [structs,structNames] = p.defaultParameters.getAllStructs();
        
        PDS = struct;
        PDS.initialParameters = structs(baseParamsLevels);
        PDS.initialParameterNames = structNames(baseParamsLevels);
        PDS.initialParameterIndices = baseParamsLevels;
        % Include a less user-hostile output struct
        if p.defaultParameters.pldaps.save.initialParametersMerged
            % Should be noted that baseParamsLevels may have been changed throughout
            % course of experiment, so this merged struct could be misleading.
            % ...activeLevels now documented for every trial though:    data{}.pldaps.activeLevels
            PDS.initialParametersMerged = mergeToSingleStruct(p.defaultParameters);
        end
        
        levelsCondition = 1:length(structs);
        levelsCondition(ismember(levelsCondition,baseParamsLevels)) = [];
        PDS.conditions = structs(levelsCondition);
        PDS.conditionNames = structNames(levelsCondition);
        PDS.data = p.data; 
        PDS.functionHandles = p.functionHandles; %#ok<STRNU>
        savedFileName = fullfile(p.defaultParameters.session.dir, p.defaultParameters.session.file);
        if p.defaultParameters.pldaps.save.v73
            save(savedFileName,'PDS','-mat','-v7.3')
        else
            save(savedFileName,'PDS','-mat')
        end
        disp('****************************************************************')
        fprintf('\tPLDAPS data file saved as:\n\t\t%s\n', savedFileName)
        disp('****************************************************************')

    end
    

    if p.trial.display.movie.create
        Screen('FinalizeMovie', p.trial.display.movie.ptr);
    end
    
    if p.defaultParameters.display.useOverlay==2
        glDeleteTextures(2,p.trial.display.lookupstexs(1));
    end
    
    % Make sure enough time passes for any pending async flips to occur
    Screen('WaitBlanking', p.trial.display.ptr);
    
    % close up shop
    Screen('CloseAll');
    IOPort('CloseAll');

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


% % % % % % % % % % % % 
% % Sub-Functions
% % % % % % % % % % % % 

%we are pausing, will create a new defaultParaneters Level where changes
%would go.
function pauseLoop(p)
        ShowCursor;
%         ListenChar(1); % is this necessary
        KbQueueRelease();
        KbQueueCreate();
        KbQueueStart();
%         altLastPressed=0;
%         ctrlLastPressed=0;
%         ctrlPressed=false;
%         altPressed=false;
        
        while p.trial.pldaps.quit==1
            %the keyboard chechking we only capture ctrl+alt key presses.
            [p.trial.keyboard.pressedQ,  p.trial.keyboard.firstPressQ]=KbQueueCheck(); % fast
            if p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.Lctrl)&&p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.Lalt)
                %D: Debugger
                if  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.dKey) 
                    disp('stepped into debugger. Type "dbcont" to start first trial...')
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
                        fprintf(2, 'No Matlab editor open -> Nothing to execute\n');
                    else
                        if isempty(activeEditor.SelectedText)
                            fprintf(2, 'Nothing selected in the active editor Widnow -> Nothing to execute\n');
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
