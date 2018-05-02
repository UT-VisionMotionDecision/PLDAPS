function [I,I2] = replayModularTrial(p, replayWindow, isGazeContingent, showWinClip, frameIndex, verbose)
%runModularTrial    runs a single Trial by calling the functions defined in
%            their substruct (found by pldaps.getModules) and the function
%            defined in p.trial.pldaps.trialFunction through different states

I=[];
I2 = [];

if nargin < 6
    verbose = false;
end

if nargin < 5
    frameIndex = [1 size(p.data{p.trial.pldaps.iTrial}.behavior.eyeAtFrame,2)];
end

if nargin < 4
    showWinClip = false;
end

if nargin<3
    isGazeContingent=false; % is the replay window gaze contingent
end

if nargin<2
    replayWindow=p.trial.display.winRect;
    if p.trial.display.useOverlay==2
        replayWindow(3)=replayWindow(3)/2;
    end
end


%get all functionHandles that we want to use
[modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs] = getModules(p);


moduleRequestedStates.frameUpdate(end)=0;
moduleRequestedStates.trialCleanUpandSave(1:end)=0;
% nFrames=size(p.data{p.trial.pldaps.iTrial}.timing.flipTimes,2);
nFrames = frameIndex(2)-frameIndex(1)+1;
I=127*ones(p.trial.display.winRect(4)-p.trial.display.winRect(2), p.trial.display.winRect(3)-p.trial.display.winRect(1), 3, nFrames, 'uint8');
I2=127*ones(replayWindow(4)-replayWindow(2), replayWindow(3)-replayWindow(1), 3, nFrames, 'uint8');

%order the framestates that we will iterate through each trial by their value
% only positive states are frame states. And they will be called in
% order of the value. Check comments in pldaps.getReorderedFrameStates
% for explanations of the default states
% negative states are special states outside of a frame (trial,
% experiment, etc)
[stateValue, stateName] = p.getReorderedFrameStates(p.trial.pldaps.trialStates,moduleRequestedStates);
nStates=length(stateValue);

runStateforModules(p,'trialSetup',modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);

%switch to high priority mode
if p.trial.pldaps.maxPriority
    oldPriority=Priority;
    maxPriority=MaxPriority('GetSecs');
    if oldPriority < maxPriority
        Priority(maxPriority);
    end
end

%will be called just before the trial starts for time critical calls to
%start data aquisition
runStateforModules(p,'trialPrepare',modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);

p.trial.flagNextTrial=0;
p.trial.iFrame=frameIndex(1);
p.trial.pldaps.quit = 0;
%%% MAIN WHILE LOOP %%%
%-------------------------------------------------------------------------%
while ~p.trial.flagNextTrial && p.trial.pldaps.quit == 0
    %go through one frame by calling the modules with the different states.
    %Save the times each state is finished.
    
    %time of the estimated next flip
%     p.trial.nextFrameTime = p.trial.stimulus.timeLastFrame+p.trial.display.ifi;
    if verbose
        fprintf('NextFrameTime: %02.4f\n', p.trial.nextFrameTime)
    end
    
    %iterate through frame states
    for iState=1:nStates
        if verbose
            disp(p.trial.dotselection.states.stateId)
            disp(stateName{iState})
        end
        
        % run state
        runStateforModules(p,stateName{iState},modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
        
        if verbose
            fprintf('FlagNext: %d\n', p.trial.flagNextTrial) % check if the trial end flag has been flipped
        end
        
       
        if strcmp(stateName{iState}, 'frameDraw') && showWinClip
            getWindow=replayWindow;
            if isGazeContingent
                getWindow([1 3])=getWindow([1 3])+p.trial.eyeX;
                getWindow([2 4])=getWindow([2 4])+p.trial.eyeY;
            end
            
            Screen('FrameOval', p.trial.display.ptr, [0 255 0], getWindow);
        end
        
        
        try
            p.trial.ttime=p.data{p.trial.pldaps.iTrial}.timing.frameStateChangeTimes(iState,p.trial.iFrame); %+ p.trial.nextFrameTime-p.trial.display.ifi;
            p.trial.stimulus.timeLastFrame = p.trial.ttime;
            p.trial.nextFrameTime = p.data{p.trial.pldaps.iTrial}.timing.frameStateChangeTimes(iState,p.trial.iFrame+1);
        catch
            p.trial.flagNextTrial = true;
            continue
        end
        
        eyeXY = p.data{p.trial.pldaps.iTrial}.behavior.eyeAtFrame(:,p.trial.iFrame);
        p.trial.eyeX = eyeXY(1);
        p.trial.eyeY = eyeXY(2);
            
        

    end
    
    
    % get screen image    
    I(:,:,:,p.trial.iFrame-(frameIndex(1)-1))=Screen('GetImage', p.trial.display.ptr, p.trial.display.winRect);% %#ok<AGROW>
    
    getWindow=replayWindow;
    if isGazeContingent
        getWindow([1 3])=getWindow([1 3])+p.trial.eyeX;
        getWindow([2 4])=getWindow([2 4])+p.trial.eyeY;
    end
    
    if getWindow(3)<=p.trial.display.winRect(3) && ...
            getWindow(1)>=0 && getWindow(2) >=0 && getWindow(4) <= p.trial.display.winRect(4)
        fprintf('grabbed frame %d\n', p.trial.iFrame)
        try
            I2(:,:,:,p.trial.iFrame-(frameIndex(1)-1))=Screen('GetImage', p.trial.display.ptr, getWindow);% %#ok<AGROW>
        catch
            I2(:,:,:,p.trial.iFrame-(frameIndex(1)-1))=I2(:,:,:,p.trial.iFrame-(frameIndex(1)-1)-1);
        end
    end

   
    
    if p.trial.iFrame >= frameIndex(2)
        p.trial.pldaps.quit = 1;
    end
    %advance to next frame, update frame index
    p.trial.iFrame = p.trial.iFrame + 1;

end    
    
    
%     if p.trial.pldaps.maxPriority
%         newPriority=Priority;
%         if round(oldPriority) ~= round(newPriority)
%             Priority(oldPriority);
%         end
%         if round(newPriority)<maxPriority
%             warning('pldaps:runTrial','Thread priority was degraded by operating system during the trial.')
%         end
%     end
    
%     runStateforModules(p,'trialCleanUpandSave',modules,moduleFunctionHandles,moduleRequestedStates,moduleLocationInputs);
    
% end %runModularTrial

