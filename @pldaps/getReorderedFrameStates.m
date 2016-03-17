function [stateValue, stateName] = getReorderedFrameStates(trialStates,moduleRequestedStates)
      %find all frame states:
      stateValue=struct2cell(trialStates);
      stateValue=[stateValue{:}];
      stateName=fieldnames(trialStates);
      stateRequested=cellfun(@(x) any(moduleRequestedStates.(x)),stateName)';

      stateName(stateValue<=0 | ~stateRequested)=[];
      stateValue(stateValue<=0 | ~stateRequested)=[];

      [stateValue, stateValueIndecies]=sort(stateValue);
      stateName=stateName(stateValueIndecies);
      
%trial states that are not in a frame are negative, just to allow both
% to be more independent
%     p.trial.pldaps.trialStates.trialSetup=-1;
%     p.trial.pldaps.trialStates.trialPrepare=-2;
%     p.trial.pldaps.trialStates.trialCleanUpandSave=-3;
%     
%     p.trial.pldaps.trialStates.experimentPostOpenScreen=-4;
%     p.trial.pldaps.trialStates.experimentPreOpenScreen=-5;
%     p.trial.pldaps.trialStates.experimentCleanUp=-6;
%     p.trial.pldaps.trialStates.experimentAfterTrials=-7;
%     
%positive states will be called in order of their value
%
%     %default order is:
%
%     %get current eyepostion, curser position or keypresses 
%     p.trial.pldaps.trialStates.frameUpdate=1;
%
%     %here you can prepare all drawing, e.g. have the dots move
%     %if you need to update to the latest e.g. eyeposition
%     %you can still do that later, this could be all expected heavy
%     %calculations
%     p.trial.pldaps.trialStates.framePrepareDrawing=2; 
%
%     %once you know you've calculated the final image, draw it
%     p.trial.pldaps.trialStates.frameDraw=3;
%     
%     %!removed for now!
%     p.trial.pldaps.trialStates.frameIdlePreLastDraw=-Inf;%4;
%     %if there is something that needs updating. here is a fucntion to do it
%     %as late as possible
%
%     %!removed for now!
%     p.trial.pldaps.trialStates.frameDrawTimecritical=-Inf;%5;
%     %if this function is not used, drawingFinished will be called after
%     %frameDraw is done, otherwise drawingFinished will not be called
%
%     p.trial.pldaps.trialStates.frameDrawingFinished=6;
% 
%     %!removed for now!
%     %this function gets called once everything got drawn, until it's time
%     %to expect (and do) the flip
%     p.trial.pldaps.trialStates.frameIdlePostDraw=-Inf;%7;
%
%     %do the flip (or when async) record the time 
%     p.trial.pldaps.trialStates.frameFlip=8;
    
end
    