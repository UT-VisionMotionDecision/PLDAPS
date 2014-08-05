function p = getQueue(p)
% p = pds.eyelink.getQueue(p)
% pdsEyelinkGetQueue pullse the values from the current Eyelink queue and
% puts them into the dv.el struct
% INPUTS
%       dv.el - must have el struct setup by pdsEyelinkSetup
%               eyelink must be recording Eyelink('StartRecording')
% OUTPUTS
%       dv.el - modified to contain
%           .samplesIn  - samples from the queue
%           .eventsIn   - events from the queue
%           .drained    - flag for whether the queue has been completely
%                         emptied

% 12/2013 jly   wrote it
if p.trial.eyelink.use
    % if time to pull samples, get them all
    while ~p.trial.eyelink.drained
        [p.trial.eyelink.samplesIn, p.trial.eyelink.eventsIn, p.trial.eyelink.drained] = Eyelink('GetQueuedData');
        
%         tic;
        % Get Eyelink samples
        if ~isempty(p.trial.eyelink.samplesIn)
            p.trial.eyelink.samples(:,(p.trial.eyelink.sampleNum+1):p.trial.eyelink.sampleNum+size(p.trial.eyelink.samplesIn,2)) = p.trial.eyelink.samplesIn;
            p.trial.eyelink.sampleNum = p.trial.eyelink.sampleNum+size(p.trial.eyelink.samplesIn,2);
        end
%         toc
        
        % Get Eyelink events
        if ~isempty(p.trial.eyelink.eventsIn)
            p.trial.eyelink.events(:,(p.trial.eyelink.eventNum+1):p.trial.eyelink.eventNum+size(p.trial.eyelink.eventsIn,2)) = p.trial.eyelink.eventsIn;
            p.trial.eyelink.eventNum = p.trial.eyelink.eventNum+size(p.trial.eyelink.eventsIn,2);
        end
        
        % Workaround - only continue if samplesIn and eventsIn were
        % empty
        if ~isempty(p.trial.eyelink.samplesIn) || ~isempty(p.trial.eyelink.eventsIn)
            p.trial.eyelink.drained = false;
        end
        
    end
   p.trial.eyelink.drained = false;
   
   if(p.trial.eyelink.useAsEyepos) 
        eInds=(p.trial.eyelink.sampleNum-p.trial.pldaps.eyeposMovAv+1):p.trial.eyelink.sampleNum;
        p.trial.eyeX = mean(p.trial.eyelink.samples(14,eInds));
        p.trial.eyeY = mean(p.trial.eyelink.samples(16,eInds));
   end
end