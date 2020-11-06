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


%% Setup and File management

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

% initialize baseParamsLevels record
p.static.pldaps.baseParamsLevels = p.trial.getAllLevels();

%% experimentPreOpenScreen (...& modularPldaps setup)
if p.trial.pldaps.useModularStateFunctions
    % Establish list of all module names    (see help pldaps.getModules)
    p.updateModNames;
    %     p.trial.pldaps.modNames.all             = getModules(p, 0);
    %     p.trial.pldaps.modNames.matrixModule    = getModules(p, bitset(0,2));
    %     p.trial.pldaps.modNames.tracker         = getModules(p, bitset(bitset(0,1),3));
    
    %experimentSetup before openScreen to allow modifyiers
    [moduleNames, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs] = getModules(p);
    runStateforModules(p,'experimentPreOpenScreen', moduleNames, moduleFunctionHandles, moduleRequestedStates, moduleLocationInputs);
end


%% Open PLDAPS windows
% Open PsychToolbox Screen
p = openScreen(p);


% Setup PLDAPS experiment condition
p.defaultParameters.pldaps.maxFrames = ceil(p.defaultParameters.pldaps.maxTrialLength * p.defaultParameters.display.frate);


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
pds.sound.setup(p);

% PLEXON
%-------------------------------------------------------------------------%
pds.plexon.spikeserver.connect(p);

% REWARD
%-------------------------------------------------------------------------%
pds.behavior.reward.setup(p);

% Initialize Datapixx including dual CLUTS and timestamp
% logging
pds.datapixx.init(p);

% HID: Initialize Keyboard, Mouse, ...etc
pds.keyboard.setup(p);

if p.trial.mouse.useLocalCoordinates
    p.trial.mouse.windowPtr=p.trial.display.ptr;
end
if ~isempty(p.trial.mouse.initialCoordinates)
    SetMouse(p.trial.mouse.initialCoordinates(1),p.trial.mouse.initialCoordinates(2),p.trial.mouse.windowPtr);
end


%% experimentPostOpenScreen
if p.trial.pldaps.useModularStateFunctions
    % Update list of module names now that everything is initialized    (see help pldaps.getModules)
    p.updateModNames;    % TODO: Should this be done BEFORE or AFTER experimentPostOpenScreen state execution? ...both is ugly, but somewhat logical.

    [moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
    runStateforModules(p,'experimentPostOpenScreen',moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
    
    p.updateModNames;
end

try
    % update display object
    % - other initializations may have made changes (i.e. setting viewdist)
    p.static.display.updateFromStruct(p.trial.display);
    
    % Create condMatrix info figure
    p.condMatrix.updateInfoFig(p);
end


%% Display output filename in command window
fprintLineBreak; fprintLineBreak('_-',32);
fprintf('PLDAPS filename\t\t\t(time %s)\n', datestr(p.defaultParameters.session.initTime, 'HH:MM'));
fprintf(2, '\t\t%s\n', p.defaultParameters.session.file);
if isfield(p.trial.pldaps.modNames,'currentStim')
    try
        fprintLineBreak('-');
        fprintf('p.trial.%s:\n',p.trial.pldaps.modNames.currentStim{1})
        disp(p.trial.(p.trial.pldaps.modNames.currentStim{1}));
    end
end
fprintLineBreak('_-', 0.5); fprintLineBreak;


%% Last chance to check variables
if(p.trial.pldaps.pause.type==1 && p.trial.pldaps.pause.preExperiment==true) %0=don't,1 is debugger, 2=pause loop
    disp('Ready to begin trials. Type "dbcont" to start first trial...')
    keyboard
    fprintf(2,'\b ~~~Start of experiment~~~\n')
end

% disable keyboard
ListenChar(2);
KbQueueFlush(p.trial.keyboard.devIdx);


%% Send expt start sync RSTART
if p.trial.datapixx.use
    % start of experiment sync signal (Plexon: set RSTART pin high, return PTB & Datapixx clock times)
    % Even if not using Plexon recording, this will establish PLDAPS exptStartTime
    p.trial.timing.exptStartTime = pds.plexon.rstart(1);
end


%% Final preparations before trial loop begins
%%%%start recoding on all controlled components this in not currently done here
% save timing info from all controlled components (datapixx, eyelink, this pc)
p = beginExperiment(p);

p.trial.flagNextTrial  = 0; % flag for ending the trial
p.trial.iFrame     = 0;  % frame index

% NOTE: the following line converts p.trial into a struct.
% ------------------------------------------------
% !!! Beyond this point, p.trial is NO LONGER A POINTER TO p.defaultParameters !!!
% !!! Contents can be accessed as normal, but params class methods will error  !!!
% ------------------------------------------------
p.trial=mergeToSingleStruct(p.defaultParameters);

% Record of baseline params class levels
p.static.pldaps.baseParamsLevels = p.defaultParameters.getAllLevels();

% Save temp file as "trial 0"
result = saveTempFile(p, true);
if ~isempty(result)
    disp(result.message)
end


% Switch to high priority mode
if p.trial.pldaps.maxPriority
    oldPriority=Priority;
    maxPriority=MaxPriority('GetSecs');
    if oldPriority < maxPriority
        Priority(maxPriority);
    end
end



%% Main trial loop
while p.trial.pldaps.iTrial < p.trial.pldaps.finish && p.trial.pldaps.quit~=2
    
    if ~p.trial.pldaps.quit
        
        % return handle status of p.trial (...this handle/struct business is so jank!)
        p.trial = p.defaultParameters;
        
        % increment trial counter
        nextTrial = p.defaultParameters.incrementTrial(+1);
        %load parameters for next trial and lock defaultParameters
        if ~isempty(p.condMatrix)
            if p.condMatrix.iPass > p.condMatrix.nPasses
                break
            end
            % create new params level for this trial
            % (...strange looking, but necessary to create a fresh 'level' for the new trial)
            p.defaultParameters.addLevels( {struct}, {sprintf('Trial%dParameters', nextTrial)});
            % Make only the baseParamsLevels and this new trial level active
            p.defaultParameters.setLevels( [p.static.pldaps.baseParamsLevels, length(p.trial.getAllLevels)] );
            % Good to go!
            % Apply upcoming condition parameters for the nextTrial
            p = p.condMatrix.nextCond(p);
            
            % % % 
            % % % % TESTING block manipulations  (**cannot be mixed within a trial**)
            % % %
% %             if iseven(p.condMatrix.iPass)
% %                 p.static.display.viewdist = 45;
% %             else
% %                 p.static.display.viewdist = 100;
% %             end
 
            
            % Sync pdsDisplay object with [.trial.display] struct
            p.trial.display = p.static.display.syncToTrialStruct(p.trial.display);
            
        elseif ~isempty(p.conditions)
            % PLDAPS 4.2 legacy mode: p.conditions must be full set of trial conds (inculding all repeats)
            p.defaultParameters.addLevels(p.conditions(nextTrial), {sprintf('Trial%dParameters', nextTrial)});
            p.defaultParameters.setLevels([p.static.pldaps.baseParamsLevels length(p.static.pldaps.baseParamsLevels)+nextTrial]);
            
        else
            p.defaultParameters.setLevels([p.static.pldaps.baseParamsLevels]);
        end

        % Document currently active levels for this trial
        p.trial.pldaps.allLevels = p.defaultParameters.getAllLevels;
        p.trial.pldaps.activeLevels = p.defaultParameters.getActiveLevels;

        % ---------- p.defaultParameters >> to >> p.trial [struct!] ----------
        % % Params class headaches:
        % The overloaded subsref function of the PARAMS class is REALLY slow
        % (repeated "find" & "cellfun" calls in particular) & limiting in increasingly 
        % problematic ways (e.g. presence of ANY function handles criples
        % all timing reliability...even if inside of a module that is never active!).
        %
        % Converting p.trial to a normal struct here bypasses these overloaded class invocations.
        % Eventually the Params class will be removed/remade all together, but
        % that day will keep getting pushed back while we do actual science. --TBC 2020-10
        
        try
            % create a deep copy in p.trial
            % - not a whole lot prettier, but avoids disc writes & should be a lot more efficient   --TBC 2020
            %   (method found in:  http://undocumentedmatlab.com/articles/general-use-object-copy)
            p.trial = getArrayFromByteStream( getByteStreamFromArray( mergeToSingleStruct(p.defaultParameters) ) );
            
        catch
            % fallback to sketchy save-reload workaround
            fprintf(2,'!')
            tmpts = mergeToSingleStruct(p.defaultParameters);
            save( fullfile(p.trial.pldaps.dirs.data, '.TEMP', 'deepTrialStruct'), '-struct', 'tmpts');
            clear tmpts
            p.trial = load(fullfile(p.trial.pldaps.dirs.data, '.TEMP', 'deepTrialStruct'));
        end
                
        % lock the defaultParameters structure
        p.defaultParameters.setLock(true);
        
        %---------------------------------------------------------------------%
        % RUN THE TRIAL
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
            % NEW:  include condition parameters in p.data, instead of relying on p.conditions being 1:1 with trial number
            dTrialStruct = getDifferenceFromStruct(p.defaultParameters, p.trial, p.static.pldaps.baseParamsLevels);
        end
        p.data{p.defaultParameters.pldaps.iTrial} = dTrialStruct;
        
        
        %% experimentAfterTrials  (Modular PLDAPS)
        if p.trial.pldaps.useModularStateFunctions && ~isempty(p.trial.pldaps.experimentAfterTrialsFunction)
            % Not clear what purpose this serves that could not be accomplished in trial cleanupandsave
            % and/or at start of next trial? ...open to suggestions. --TBC 2017-10
            oldptrial=p.trial;
            [moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
            p.defaultParameters.setLevels(p.static.pldaps.baseParamsLevels);
            p.trial=mergeToSingleStruct(p.defaultParameters);
            p.defaultParameters.setLock(true);
            runStateforModules(p,'experimentAfterTrials',moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
            
            p.defaultParameters.setLock(false);
            betweenTrialsStruct=getDifferenceFromStruct(p.defaultParameters,p.trial);
            if(~isequal(struct,betweenTrialsStruct))
                p.defaultParameters.addLevels({betweenTrialsStruct}, {sprintf('experimentAfterTrials%dParameters', p.defaultParameters.pldaps.iTrial)});
                p.static.pldaps.baseParamsLevels = [p.static.pldaps.baseParamsLevels length(p.defaultParameters.getAllLevels())];
            end
            
            p.trial=oldptrial;
        end
        
    else
        
        %% Pause experiment
        % ...should we halt eyelink, datapixx, etc?
        ptype = p.trial.pldaps.pause.type;
        % [ptype]: 1=standard pause, 2=pause loop (hacky O.T.F. keyboard polling...prob code detritus)
        
        % p.trial is once again a pointer (!?)
        p.trial = p.defaultParameters; % This effectively resets the .pldaps.quit~=0 that triggered execution of this block
        
        % NOTE: This will ALWAYS create a new 'level' (even if nothing is changed during pause)
        % ...doesn't seem to be the original intention, but allows changes during pause to be carried
        % over without overwriting prior settings, or getting lost in .conditions parameters. --TBC 2017-10
        p.defaultParameters.addLevels({struct}, {sprintf('PauseAfterTrial%dParameters', p.defaultParameters.pldaps.iTrial)});
        
        if ptype %==1
            ListenChar(0);
            % p.trial
            fprintf('Experiment paused. Type "dbcont" to continue...\n')
            keyboard %#ok<MCKBD>
            fprintf(2,'\b...experiment resumed.\n')
            ListenChar(2);

        % elseif ptype==2
            % "pauseLoop" is dead. Long live, pauseLoop!
        end
        
        % Clear out keyboard queue
        KbQueueFlush(p.trial.keyboard.devIdx);
        
        % Check for anything that was changed/added during pause
        allStructs = p.defaultParameters.getAllStructs();
        if ~isequal(struct, allStructs{end})
            % If so, add this new level to the "p.static.pldaps.baseParamsLevels" & continue,
            p.static.pldaps.baseParamsLevels = [p.static.pldaps.baseParamsLevels length(allStructs)];
        else
            % Else, set active levels back to the baseParamsLevels and carry on...
            p.defaultParameters.setLevels( p.static.pldaps.baseParamsLevels );
        end
    end
    
end

%% Clean up & bookkeeping post-trial execution loop

%make the session parameterStruct active
% NOTE: This potentially obscures hierarchy levels (i.e. "PauseAfterTrial##Parameters") that
%       are likely inconsistent throughout session. ...each trial data now includes a list
%       of active hierarchy levels in .pldaps.activeLevels. --TBC 2017-10
p.defaultParameters.setLevels(p.static.pldaps.baseParamsLevels);
p.trial = p.defaultParameters;

% return cursor and command-line control
ListenChar(0);
Priority(0);

% p =  ; The following should be operating on pldaps class handles, thus no need for outputs. --tbc.
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
    pds.sound.clearBuffer(p);
    % Close the audio device:
    PsychPortAudio('Close', p.defaultParameters.sound.master);
end

if p.trial.pldaps.useModularStateFunctions
    [moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);
    runStateforModules(p,'experimentCleanUp',moduleNames,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
end

%% Send expt end sync RSTOP
if p.trial.datapixx.use
    % start of experiment sync signal (Plexon: set RSTART pin high, return PTB & Datapixx clock times)
    p.trial.timing.exptEndTime = pds.plexon.rstart(0);
end

%% Close Eyelink
if p.trial.eyelink.use
    pds.eyelink.finish(p);
    % EDF data transfer:
    % Time consuming transfer is self contained, yet hogs all of matlab attention while transferring
    % RECOMMENDED: Set .eyelink.saveEDF == false; then initialize transfer of all corresponding
    % eyelink EDF data files at the end of a recording session/day using:
    %       pds.eyelink.fetchEdf.m
end


%% PDS output:  Compile & save the data
if ~p.trial.pldaps.nosave
    % Use pldaps.save method to save PLDAPS experiment session
    % - Converts pldaps object to a struct containing standard/unpacked data & parameters output fields:
    %   [.baseParams, .data{}, .conditions [and/or] .condMatrix, .static]
    p.save;
    
    
    %% Detect & report dropped frames
    frameDropCutoff = 1.1;
    frameDrops = cell2mat(cellfun(@(x) [sum(diff(x.timing.flipTimes(1,:))>(frameDropCutoff*p.trial.display.ifi)), x.iFrame], p.data, 'uni',0)');
    ifiMu = mean(cell2mat(cellfun(@(x) diff(x.timing.flipTimes(1,:)), p.data, 'uni',0)));
    if 1
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


%% Make sure enough time passes for any pending async flips to occur
Screen('WaitBlanking', p.trial.display.ptr);

if p.trial.datapixx.use
    % If in ProPixx RB3D mode, return DLP sequence to normal
    if p.trial.datapixx.rb3d
        % NOTE:  Returning DLP sequence program to zero
        % fails properly disable the stereo polarizer device.
        % Just leave it in dirty state for now... TBC 2018-10
        %         Datapixx('SetPropixxDlpSequenceProgram',0);
    end
end    


% close up shop
sca;    Screen('CloseAll');


end %run.m


% % % % % % % % % % % %
% % Sub-Functions
% % % % % % % % % % % %

% NONE.
