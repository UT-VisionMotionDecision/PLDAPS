function p = replay(p,input)
% [p] = replay()
if ischar(input)
    load(input,'-mat');
else
    PDS=input;
end

%get the trial Numbers form the condition Parameters
conditionTrials=cellfun(@(x) textscan(x,'Trial%dParameters'),PDS.conditionNames);
conditionTrials=[conditionTrials{:}];

%the initial Parameters have both all levels that are defined at the
%ebginning at the experiment, but also newer levels created when the
%experiment was paused to change parameters.
%The pre experiemnt parameters need to be added to each trial
%The pause parameters need to be addedf to all trials after the pause
%So here we test which parameters are pause parameters
[a,b]=p.defaultParameters.getAllStructs();
initialParameterNames= [b(1:end) PDS.initialParameterNames];
initialParameters= [a(1:end) PDS.initialParameters];

afterpauseparms=cellfun(@(x) textscan(x,'PauseAfterTrial%dParameters'),initialParameterNames);
isafterpauseparm=~cellfun(@isempty,afterpauseparms);
%and sepereate the pre experiment levels
preLevels=find(~isafterpauseparm);
preOffset=length(initialParameterNames);
%from the pause levels and get the trials after which they where defined
afterPauseLevels=find(isafterpauseparm);
afterPauseTrials=[afterpauseparms{isafterpauseparm}];

%this will override all parameters before. probabbly not a good longterm
%idea.
newDisplay=p.trial.display;
newparams=p.trial;

p.defaultParameters=params([initialParameters PDS.conditions],[initialParameterNames PDS.conditionNames]);
p.trial=p.defaultParameters;

p.defaultParameters.setLevels(preLevels);
%convert luts
if p.defaultParameters.datapixx.use
    clutNames=fieldnames(p.trial.display.clut);
    for c=1:length(clutNames)
        cind=p.trial.display.clut.(clutNames{c})(1);
        p.trial.display.clut.(clutNames{c})=p.defaultParameters.display.humanCLUT(cind+1,:)';
    end
end

%     p.trial.display=oldDisplay;

    p.defaultParameters.pldaps.trialFunction='opticflow.replay';
    p.defaultParameters.pldaps.trialMasterFunction = 'runAnalysis';
    p.defaultParameters.datapixx.use=false;
    p.defaultParameters.sound.flagBuzzer=0;
    p.defaultParameters.sound.use=1;
   
    p.defaultParameters.spikeserver.use = 0;
    p.defaultParameters.eyelink.use = 0;

    
p.trial.pldaps.pause=newparams.pldaps.pause;
    
p.data=PDS.data;
p.functionHandles=PDS.functionHandles;
% p.trial.postanalysis=PDS.postanalysis;

%%todo Aspectratio
% p.trial.display.widthcm=PDS.initialParametersMerged.display.widthcm;
% p.trial.display.heightcm=PDS.initialParametersMerged.display.heightcm;
% p.trial.display.viewdist=PDS.initialParametersMerged.display.viewdist;
p.trial.display.screenSize=newDisplay.screenSize;
p.trial.display.scrnNum=newDisplay.scrnNum;
p.trial.display.useOverlay=newDisplay.useOverlay;
p.trial.display.colorclamp=newDisplay.colorclamp;
p.trial.display.forceLinearGamma=newDisplay.forceLinearGamma;
if isfield(newDisplay,'gamma')
    p.trial.display.gamma=newDisplay.gamma;
end
p.trial.display.bgColor=newDisplay.bgColor;

p.defaultParameters.pldaps.dirs.wavfiles=newparams.pldaps.dirs.wavfiles;

KbQueueReserve(1, 2,[])

try
    %% Setup and File management
    % Ensure we have an experimentSetupFile set and verify output file
    
    
    % pick YOUR experiment's main CONDITION file-- this is where all
    % expt-specific stuff emerges from
%     if isempty(p.defaultParameters.session.experimentSetupFile)
%         [cfile, cpath] = uigetfile('*.m', 'choose condition file', [base '/CONDITION/debugcondition.m']); %#ok<NASGU>
%         
%         dotm = strfind(cfile, '.m');
%         if ~isempty(dotm)
%             cfile(dotm:end) = [];
%         end
%         p.defaultParameters.session.experimentSetupFile = cfile;
%     end
%              
%     p.defaultParameters.session.initTime=now;
%         
%     if ~p.defaultParameters.pldaps.nosave
%         p.defaultParameters.session.dir = p.defaultParameters.pldaps.dirs.data;
%         p.defaultParameters.session.file = [p.defaultParameters.session.subject datestr(p.defaultParameters.session.initTime, 'yyyymmdd') p.defaultParameters.session.experimentSetupFile datestr(p.defaultParameters.session.initTime, 'HHMM') '.PDS'];
% %         p.defaultParameters.session.file = fullfile(p.defaultParameters.pldaps.dirs.data, [p.defaultParameters.session.subject datestr(p.defaultParameters.session.initTime, 'yyyymmdd') p.defaultParameters.session.experimentSetupFile datestr(p.defaultParameters.session.initTime, 'HHMM') '.PDS']);
%         
%         if p.defaultParameters.pldaps.useFileGUI
%             [cfile, cdir] = uiputfile('.PDS', 'specify data storage file', fullfile( p.defaultParameters.session.dir,  p.defaultParameters.session.file));
%             if(isnumeric(cfile)) %got canceled
%                 error('pldaps:run','file selection canceled. Not sure what the correct default bevaior would be, so stopping the experiment.')
%             end
%             p.defaultParameters.session.dir = cdir;
%             p.defaultParameters.session.file = cfile;
%         end
%     else
%         p.defaultParameters.session.file='';
%         p.defaultParameters.session.dir='';
%     end
        
    %% Open PLDAPS windows
    % Open PsychToolbox Screen
    p = openScreen(p);
    
    %% rescale dot drawing
    p.trial.replay.xfactor= p.trial.display.pWidth/PDS.initialParametersMerged.display.pWidth;
    p.trial.replay.yfactor= p.trial.display.pHeight/PDS.initialParametersMerged.display.pHeight;
    
    % Setup PLDAPS experiment condition
%     p.defaultParameters.pldaps.maxFrames=p.defaultParameters.pldaps.maxTrialLength*p.defaultParameters.display.frate;
%     p = feval(p.defaultParameters.session.experimentSetupFile, p);
    
%             %
%             % Setup Photodiode stimuli
%             %-------------------------------------------------------------------------%
%             if(p.trial.pldaps.draw.photodiode.use)
%                 makePhotodiodeRect(p);
%             end
%     
%             % Tick Marks
%             %-------------------------------------------------------------------------%
%             if(p.trial.pldaps.draw.grid.use)
%                 p = initTicks(p);
%             end


            %get and store changes of current code to the git repository
            p = pds.git.setup(p);
            
            %things that were in the conditionFile
            p = pds.eyelink.setup(p);
    
            %things that where in the default Trial Structure
            
            % Audio
            %-------------------------------------------------------------------------%
            p = pds.audio.setup(p);
            
            % Audio
            %-------------------------------------------------------------------------%
            p = pds.spikeserver.connect(p);
            
            % From help PsychDataPixx:
            % Timestamping is disabled by default (mode == 0), as it incurs a bit of
            % computational overhead to acquire and log timestamps, typically up to 2-3
            % msecs of extra time per 'Flip' command.
            % Buffer is collected at the end of the expeiment!
            PsychDataPixx('LogOnsetTimestamps',p.trial.datapixx.LogOnsetTimestampLevel);%2
            PsychDataPixx('ClearTimestampLog');
            
    
            % Initialize Datapixx for Dual CLUTS
            p = pds.datapixx.init(p);
            
            pds.keyboard.setup();
    

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
    
    %save defaultParameters as trial 0
    trialNr=0;
    p.trial.pldaps.iTrial=0;
    p.trial=mergeToSingleStruct(p.defaultParameters);
%     result = saveTempFile(p); 
%     if ~isempty(result)
%         disp(result.message)
%     end
%     
    
    %now setup everything for the first trial
%    
% %     p.defaultParameters.pldaps.iTrial=trialNr;
%     
%     %we'll have a trialNr counter that the trial function can tamper with?
%     %do we need to lock the defaultParameters to prevent tampering there?
%     levelsPreTrials=p.defaultParameters.getAllLevels();
% %     p.defaultParameters.addLevels(p.conditions(trialNr), {['Trial' num2str(trialNr) 'Parameters']});
%     
%     %for now all structs will be in the parameters class, first
%     %levelsPreTrials, then we'll add the condition struct before each trial.
% %     p.defaultParameters.setLevels([levelsPreTrials length(levelsPreTrials)+trialNr])
% %     p.defaultParameters.pldaps.iTrial=trialNr;
% %     p.trial=mergeToSingleStruct(p.defaultParameters);
    
    %only use p.trial from here on!
    p.defaultParameters.pldaps.finish=length(conditionTrials);
    
    %% main trial loop %%
    while p.trial.pldaps.iTrial < p.trial.pldaps.finish && p.trial.pldaps.quit~=2
        
        if p.trial.pldaps.quit == 0
            
           %load parameters for next trial and lock defaultsParameters
           trialNr=trialNr+1;
%            p.defaultParameters.addLevels(p.conditions(trialNr), {['Trial' num2str(trialNr) 'Parameters']});
%            p.defaultParameters.setLevels([levelsPreTrials length(levelsPreTrials)+trialNr]);
%            p.defaultParameters.pldaps.iTrial=trialNr;
%            p.trial=mergeToSingleStruct(p.defaultParameters);
            
           
            %set previous values for that trial.
           functionLevels=[preLevels afterPauseLevels(trialNr>afterPauseTrials) preOffset+find(conditionTrials==trialNr)];
           p.defaultParameters.setLevels(functionLevels);
           p.defaultParameters.pldaps.iTrial=trialNr;
%             p.defaultParameters.pldaps.finish=length(conditionTrials)+1;
           p.trial=p.defaultParameters.mergeToSingleStruct();
           
           p.defaultParameters.setLock(true);
            
           % run trial
           p = feval(p.trial.pldaps.trialMasterFunction,  p);
            
           %unlock the defaultParameters
           p.defaultParameters.setLock(false); 
            
%            %save tmp data
%            result = saveTempFile(p); 
%            if ~isempty(result)
%                disp(result.message)
%            end
%                       
%            %store the difference of the trial struct to .data
%            dTrialStruct=getDifferenceFromStruct(p.defaultParameters,p.trial);
%            p.data{trialNr}=dTrialStruct;

            if isfield(p.trial,'replay')
                p.data{trialNr}.replay=p.trial.replay;
            end
           
            if all(all(p.trial.stimulus.dots.XYd==PDS.data{trialNr}.stimulus.dots))
                display(sprintf('trial %i replayed',trialNr));
                p.data{trialNr}.replay.success=true;
%                 good(iTrial)=true;
            else
                display(sprintf('trial %i replayed, but there seems to be a reconstruction error',trialNr));
                p.data{trialNr}.replay.success=false;
%                 good(iTrial)=false;
            end

            
        else %dbquit ==1 is meant to be pause. should we halt eyelink, datapixx, etc?
            %create a new level to store all changes in, 
            %load only non trial paraeters
            pause=p.trial.pldaps.pause.type;
            p.trial=p.defaultParameters;
            
            p.defaultParameters.addLevels({struct}, {['PauseAfterTrial' num2str(trialNr) 'Parameters']});
            p.defaultParameters.setLevels([preLevels length(p.defaultParameters.getAllLevels())]);
            
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
%             pds.datapixx.refresh(dv);

            %now I'm assuming that nobody created new levels,
            %but I guess when you know how to do that
            %you should also now how to not skrew things up
            allStructs=p.defaultParameters.getAllStructs();
            if(~isequal(struct,allStructs{end}))
                preLevels=[preLevels length(allStructs)]; %#ok<AGROW>
            end
        end
        
    end
    
    %make the session parameterStruct active
    p.defaultParameters.setLevels(preLevels);
    p.trial = p.defaultParameters;
    
    % return cursor and command-line control
    ShowCursor;
    ListenChar(0);
    Priority(0);
    
    p = pds.eyelink.finish(p);
    p = pds.spikeserver.disconnect(p);
    if(p.defaultParameters.datapixx.use)
        %start adc data collection if requested
        pds.datapixx.adc.stop(p);
        
        status = PsychDataPixx('GetStatus');
        if status.timestampLogCount
            p.defaultParameters.datapixx.timestamplog = PsychDataPixx('GetTimestampLog', 1);
        end
    end
    
    
%     if ~p.defaultParameters.pldaps.nosave
%         [structs,structNames] = p.defaultParameters.getAllStructs();
%         
%         PDS=struct;
%         PDS.initialParameters=structs(levelsPreTrials);
%         PDS.initialParameterNames=structNames(levelsPreTrials);
%         PDS.initialParametersMerged=mergeToSingleStruct(p.defaultParameters); %too redundant?
%         
%         levelsCondition=1:length(structs);
%         levelsCondition(ismember(levelsCondition,levelsPreTrials))=[];
%         PDS.conditions=structs(levelsCondition);
%         PDS.conditionNames=structNames(levelsCondition);
%         PDS.data=p.data; 
%         PDS.functionHandles=p.functionHandles;
%         save(fullfile(p.defaultParameters.session.dir, p.defaultParameters.session.file),'PDS','-mat')
%     end
    

    if p.trial.display.movie.create
        Screen('FinalizeMovie', p.trial.display.movie.ptr);
    end
    Screen('CloseAll');

    sca;
    
catch me
    sca
    
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
                           pds.eyelink.calibrate(dv);
                       end
                    catch ME
                        display(ME);
                    end

                %M: Manual reward
                elseif  p.trial.keyboard.firstPressQ(p.trial.keyboard.codes.mKey)
                    if p.trial.datapixx.use
                        pds.datapixx.analogOut(p.trial.stimulus.rewardTime)
                        pds.datapixx.flipBit(p.trial.event.REWARD);
                    end
                    p.trial.ttime = GetSecs - p.trial.trstart;
                    p.trial.stimulus.timeReward(:,p.trial.iReward) = [p.trial.ttime p.trial.stimulus.rewardTime];
                    p.trial.stimulus.iReward = p.trial.iReward + 1;
                    PsychPortAudio('Start', p.trial.sound.reward);

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
