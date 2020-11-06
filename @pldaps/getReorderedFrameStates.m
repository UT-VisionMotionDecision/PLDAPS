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
      
end

% ----------------------------------------------------------------
% NEGATIVE states that are only executed ONCE per [trial] or [experiment]
% - order/timing predetermined by PLDAPS methods:  run.m  &  runModularTrial.m
%     
% POSITIVE states are evaluated on EVERY display [frame] update/refresh
% - order of execution by ascending state value (assigned in pldapsClassDefaults.m)
% ----------------------------------------------------------------
% Default [p.trial.pldaps.trialStates] order:
% 
%   .experimentPreOpenScreen    = -5
%   .experimentPostOpenScreen   = -6
%   
%     .trialSetup               = -1
%     .trialPrepare             = -2
% 
%       .frameUpdate            =  1
%       .framePrepareDrawing    =  2
%       .frameDraw              =  3
%       .frameGLDrawLeft        =  4
%       .frameGLDrawRight       =  5
%       .frameDrawingFinished   =  6
%       .frameFlip              =  7
% 
%     .trialItiDraw             = -3
%     .trialCleanUpandSave      = -4
%   .experimentAfterTrials      = -7
%   .experimentCleanUp          = -8
%     
% 
% ----------------------------------------------------------------
% Typical operations/uses of each state:
% 
% [.frameUpdate]
%   - get current eyepostion, curser position or keypresses 
%
% [.framePrepareDrawing]
%     %here you can prepare all drawing, e.g. have the dots move
%     %if you need to update to the latest e.g. eyeposition
%     %you can still do that later, this could be all expected heavy
%     %calculations
%
% [.frameDraw]
%     %once you know you've calculated the final image, draw it
%     
% [.frameDrawingFinished]
%   - last chance for any non-drawing operations before frame flip
%
% [.frameFlip]
%   - flip the PTB screen to display next stimulus frame
%   - record timing of presentation
%   - this state is typically only utilized by pldapsDefaultTrial.m
%     , use within own modules/code is not prohibited, but not recommended either.
% 
