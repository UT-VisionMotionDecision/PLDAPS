function p = run(p)
%run    run a new experiment for a previuously created pldaps class
% p = run(p)
% PLDAPS (Plexon Datapixx PsychToolbox) version 4.2
%       run is a wrapper for calling PLDAPS package files
%           It opens the PsychImaging pipeline and initializes datapixx for
%           dual color lookup tables.
%
% 10/2011 jly wrote it (modified from letsgorun.m)
% 12/2013 jly reboot. updated to version 3 format.
% 04/2014 jk  moved into a pldaps class; adapated to new class structure
% 2018-06-06 tbc  Updating usage & application of p.conditions to function
%                 as a proper conditions matrix
%
%TODO:
% Sub-System for module creation & interaction
% - currently just pldapsModule.m for module creation
%
%
%
% make HideCursor optional


% try
%% Setup and File management
% clean IOPort handles (no PTB method to retrieve previously opened IOPort handles, so might as well clean slate)
% % % IOPort('CloseAll');

if ~isfield(p.trial.pldaps,'verbosity')
    p.trial.pldaps.verbosity = 3;
end
Screen('Preference','Verbosity', p.trial.pldaps.verbosity);
IOPort('Verbosity', p.trial.pldaps.verbosity-1); % quieter
PsychPortAudio('Verbosity', p.trial.pldaps.verbosity-1); % quieter

% Each PLDAPS instance can only be run once. Abort if it appears this has already occurred
if isField(p.defaultParameters, 'session.initTime')
    warning('pldaps:run', 'pldaps objects appears to have been run before. A new pldaps object is needed for each run');
    return
end

p.defaultParameters.session.initTime=now;
% use .initTime to seed session random number generator
rng(100*sum(datevec(p.defaultParameters.session.initTime)), 'twister');
p.defaultParameters.session.rng = rng;
% place iTrial counter in SessionParameters level of params hierarchy
p.defaultParameters.pldaps.iTrial = 0;

%% Initialize filename & all data directories for this PLDAPS session
p = setupSessionFiles(p);


%% experimentPreOpenScreen (...& modularPldaps setup)
if p.trial.pldaps.useModularStateFunctions
    % Establish list of all module names
    p.trial.pldaps.modNames.all = getModules(p, 0);
    p.trial.pldaps.modNames.matrixModule = getModules(p, bitset(0,2));
    
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
[p.trial.eyeX, p.trial.eyeY, p.trial.eyeDelta] = deal(nan);

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


%% Display output filename in command window
fprintLineBreak; fprintLineBreak('_-',32);
fprintf('PLDAPS filename\t\t\t(time %s)\n', datestr(p.defaultParameters.session.initTime, 'HH:MM'));
fprintf(2, '\t\t%s\n', p.defaultParameters.session.file);
fprintLineBreak('_-',32);


%% Last chance to check variables
if(p.trial.pldaps.pause.type==1 && p.trial.pldaps.pause.preExperiment==true) %0=don't,1 is debugger, 2=pause loop
    disp('Ready to begin trials. Type "dbcont" to start first trial...')
    keyboard
    fprintf(2,'\b ~~~Start of experiment~~~\n')
end


%% Final preparations before trial loop begins
%%%%start recoding on all controlled components this in not currently done here
% save timing info from all controlled components (datapixx, eyelink, this pc)
p = beginExperiment(p);

% disable keyboard
ListenChar(2);
HideCursor;
KbQueueFlush(p.trial.keyboard.devIdx);

p.trial.flagNextTrial  = 0; % flag for ending the trial
p.trial.iFrame     = 0;  % frame index

% Save defaultParameters as trial 0
% NOTE: the following line converts p.trial into a struct.
% ------------------------------------------------
% !!! Beyond this point, p.trial is NO LONGER A POINTER TO p.defaultParameters !!!
% !!! Contents can be accessed as normal, but params class methods will error  !!!
% ------------------------------------------------
p.trial=mergeToSingleStruct(p.defaultParameters);
result = saveTempFile(p);
if ~isempty(result)
    disp(result.message)
end

% Record of baseline params class levels
baseParamsLevels = p.defaultParameters.getAllLevels();

%% Main trial loop
while p.trial.pldaps.iTrial < p.trial.pldaps.finish && p.trial.pldaps.quit~=2
    
    if ~p.trial.pldaps.quit
        
        % return handle status of p.trial (...this handle/struct business is so jank!)
        p.trial = p.defaultParameters;

        % increment trial counter
        nextTrial = p.defaultParameters.incrementTrial(+1);
        %load parameters for next trial and lock defaultsParameters
        if ~isempty(p.condMatrix)
            if p.condMatrix.iPass > p.condMatrix.nPasses
                break
            end
            % create new params level for this trial
            % (...strange looking, but necessary to create a fresh 'level' for the new trial)
            p.defaultParameters.addLevels( {struct}, {sprintf('Trial%dParameters', nextTrial)});
            % Make only the baseParamsLevels and this new trial level active
            p.defaultParameters.setLevels( [baseParamsLevels, length(p.trial.getAllLevels)] );
            % Good to go!
            % Apply upcoming condition parameters for the nextTrial
            p = p.condMatrix.nextCond(p);
            
        elseif ~isempty(p.conditions)
            % PLDAPS 4.2 legacy mode: p.conditions must be full set of trial conds (inculding all repeats)
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
        tmpts = mergeToSingleStruct(p.defaultParameters);
        save( fullfile(p.trial.pldaps.dirs.data, '.TEMP', 'deepTrialStruct'), '-struct', 'tmpts');
        clear tmpts
        p.trial = load(fullfile(p.trial.pldaps.dirs.data, '.TEMP', 'deepTrialStruct'));
        
        % Document currently active levels for this trial
        p.trial.pldaps.activeLevels = p.defaultParameters.getActiveLevels;
        
        % lock the defaultParameters structure
        p.defaultParameters.setLock(true);
        
        %---------------------------------------------------------------------%
        % RUN THE TRIAL
        %            KbQueueStop
        %            keyboard
        %            KbQueueStart
        p = feval(p.trial.pldaps.trialMasterFunction,  p);
        %---------------------------------------------------------------------%
        
        %unlock the defaultParameters
        p.defaultParameters.setLock(false);
        
        %save TEMP data file
        result = saveTempFile(p);
        if ~isempty(result)
            disp(result.message)
        end
        
        %% p.data{i}: Partition trial data
        % Compile all data and parameters collected/changed during this trial
        if p.defaultParameters.pldaps.save.mergedData
            %store the complete trial struct to .data
            dTrialStruct = p.trial;
        else
            %store the difference of the trial struct to .data
%               dTrialStruct = getDifferenceFromStruct(p.defaultParameters, p.trial);
            % NEW:  include condition parameters in p.data, instead of relying on p.conditions being 1:1 with trial number
            dTrialStruct = getDifferenceFromStruct(p.defaultParameters, p.trial, baseParamsLevels);
        end
        p.data{p.defaultParameters.pldaps.iTrial} = dTrialStruct;
        
        %% experimentAfterTrials  (Modular PLDAPS)
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
                baseParamsLevels=[baseParamsLevels length(p.defaultParameters.getAllLevels())]
            end
            
            p.trial=oldptrial;
        end
        
    else
        
        %% Pause experiment
        % ...should we halt eyelink, datapixx, etc?
        ptype = p.trial.pldaps.pause.type;
        % [ptype]: 1=standard pause, 2=pause loop (hacky O.T.F. keyboard polling...prob code detritus)
        
        % p.trial is once again a pointer (!)
        p.trial = p.defaultParameters; % This effectively resets the .pldaps.quit~=0 that triggered execution of this block
        
        % NOTE: This will ALWAYS create a new 'level' (even if nothing is changed during pause)
        % ...doesn't seem to be the original intention, but allows changes during pause to be carried
        % over without overwriting prior settings, or getting lost in .conditions parameters. --TBC 2017-10
        p.defaultParameters.addLevels({struct}, {sprintf('PauseAfterTrial%dParameters', p.defaultParameters.pldaps.iTrial)});
        
        if ptype==1
            ListenChar(0);
            ShowCursor;
            % p.trial
            fprintf('Experiment paused. Type "dbcont" to continue...\n')
            keyboard %#ok<MCKBD>
            fprintf(2,'\b...experiment resumed.\n')
            ListenChar(2);
            HideCursor;
        elseif ptype==2
            pauseLoop(p);
        end
        
        % Clear out keyboard queue
        KbQueueFlush(p.trial.keyboard.devIdx);
        
        % Check for anything that was changed/added during pause
        allStructs = p.defaultParameters.getAllStructs();
        if ~isequal(struct, allStructs{end})
            % If so, add this new level to the "baseParamsLevels" & continue,
            baseParamsLevels=[baseParamsLevels length(allStructs)];
        else
            % Else, set active levels back to the baseParamsLevels and carry on...
            p.defaultParameters.setLevels( baseParamsLevels );
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
pds.behavior.reward.finish(p);
if p.trial.datapixx.use
    % stop adc data collection
    pds.datapixx.adc.stop(p);
    
    status = PsychDataPixx('GetStatus');
    if status.timestampLogCount
        p.trial.datapixx.timestamplog = PsychDataPixx('GetTimestampLog', 1);
    end
end

if p.trial.sound.use
    pds.audio.clearBuffer(p);
    % Close the audio device:
    PsychPortAudio('Close', p.defaultParameters.sound.master);
end

if p.trial.pldaps.useModularStateFunctions
    [moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
    runStateforModules(p,'experimentCleanUp',moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
end


%% PDS output:  Compile & save the data
if ~p.trial.pldaps.nosave
    % create output struct
    PDS = struct;
    % get the raw contents of Params hierarchy (...not for mere mortals)
    [rawParamsStruct, rawParamsNames] = p.defaultParameters.getAllStructs();
    % Partition baseline parameters present at the onset of all trials (*)
    PDS.pdsCore.initialParameters       = rawParamsStruct(baseParamsLevels);
    PDS.pdsCore.initialParameterNames   = rawParamsNames(baseParamsLevels);
    PDS.pdsCore.initialParameterIndices = baseParamsLevels;
    % Include a less user-hostile output struct
    PDS.baseParams = mergeToSingleStruct(p.defaultParameters);
    % ! ! ! NOTE: baseParamsLevels can be changed during experiment (i.e. during a pause),
    % ! ! ! so this merged struct could be misleading.
    % ! ! ! Truly activeLevels are documented on every trial in:  data{}.pldaps.activeLevels
    % ! ! ! Reconstruct them by p
    
    levelsCondition = 1:length(rawParamsStruct);
    levelsCondition(ismember(levelsCondition, baseParamsLevels)) = [];
    if ~isempty(p.condMatrix)
        PDS.condMatrix = p.condMatrix;
        PDS.condMatrix.H = [];
    end
    PDS.conditions = rawParamsStruct(levelsCondition);
    PDS.conditionNames = rawParamsNames(levelsCondition);
    PDS.data = p.data;
    PDS.functionHandles = p.functionHandles; %#ok<STRNU>
    savedFileName = fullfile(p.trial.session.dir, 'pds', p.trial.session.file);
    save(savedFileName,'PDS','-mat')
    disp('****************************************************************')
    fprintf('\tPLDAPS data file saved as:\n\t\t%s\n', savedFileName)
    disp('****************************************************************')
    
    % Detect & report dropped frames
    frameDropCutoff = 1.1;
    frameDrops = cell2mat(cellfun(@(x) [sum(diff(x.timing.flipTimes(1,:))>(frameDropCutoff*p.trial.display.ifi)), x.iFrame], p.data, 'uni',0)');
    ifiMu = mean(cell2mat(cellfun(@(x) diff(x.timing.flipTimes(1,:)), p.data, 'uni',0)));
    if 1%sum(frameDrops(:,1))>0
        fprintf(2, '\t**********\n');
        fprintf(2,'\t%d (of %d) ', sum(frameDrops,1)); fprintf('trial frames exceeded %3.0f%% of expected ifi\n', frameDropCutoff*100);
        fprintf('\tAverage ifi = %3.2f ms (%2.2f Hz)', ifiMu*1000, 1/ifiMu);
        if isfield(p.data{1},'frameRenderTime')
            fprintf(',\t  median frameRenderTime = %3.2f ms\n', 1000*median(cell2mat(cellfun(@(x) x.frameRenderTime', p.data, 'uni',0)')));
        end
        fprintf(2, '\t**********\n');
    end
    
end

%% Close up shop & free up memory
if p.trial.display.useOverlay==2
    glDeleteTextures(2,p.trial.display.lookupstexs(1));
end

% Clean up stray glBuffers (...else crash likely on subsequent runs)
if isfield(p.trial.display, 'useGL') && p.trial.display.useGL
    global glB GL %#ok<TLEV>
    if isstruct(glB)
        fn1 = fieldnames(glB);
        for i = 1:length(fn1)
            if isstruct(glB.(fn1{i})) && isfield(glB.(fn1{i}),'h')
                % contains buffer handle
                glDeleteBuffers(1, glB.(fn1{i}).h);
                % fprintf('\tDeleted glBuffer glB.%s\n', fn1{i});
                glB = rmfield(glB, fn1{i});
                
            elseif glIsProgram(glB.(fn1{i}))
                % is a GLSL program
                glDeleteProgram(glB.(fn1{i}))
            end
        end
        clearvars -global glB
    end
end

% Make sure enough time passes for any pending async flips to occur
Screen('WaitBlanking', p.trial.display.ptr);

if p.trial.datapixx.use
    % If in ProPixx RB3D mode, return DLP sequence to normal
    if p.trial.datapixx.rb3d
        Datapixx('SetPropixxDlpSequenceProgram',0);
    end
end    
% close up shop
Screen('CloseAll');

% sca;

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
