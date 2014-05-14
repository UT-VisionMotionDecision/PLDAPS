function dv = eyelinkGetQueue(dv)
% dv = pdsEyelinkGetQueue(dv)
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
if dv.trial.eyelink.use
    % if time to pull samples, get them all
    while ~dv.trial.eyelink.drained
        [dv.trial.eyelink.samplesIn, dv.trial.eyelink.eventsIn, dv.trial.eyelink.drained] = Eyelink('GetQueuedData');
        
%         tic;
        % Get Eyelink samples
        if ~isempty(dv.trial.eyelink.samplesIn)
            dv.trial.eyelink.samples(:,dv.trial.eyelink.sampleNum:dv.trial.eyelink.sampleNum+size(dv.trial.eyelink.samplesIn,2)-1) = dv.trial.eyelink.samplesIn;
            dv.trial.eyelink.sampleNum = dv.trial.eyelink.sampleNum+size(dv.trial.eyelink.samplesIn,2);
        end
%         toc
        
        % Get Eyelink events
        if ~isempty(dv.trial.eyelink.eventsIn)
            dv.trial.eyelink.events(:,dv.trial.eyelink.eventNum:dv.trial.eyelink.eventNum+size(dv.trial.eyelink.eventsIn,2)-1) = dv.trial.eyelink.eventsIn;
            dv.trial.eyelink.eventNum = dv.trial.eyelink.eventNum+size(dv.trial.eyelink.eventsIn,2);
        end
        
        % Workaround - only continue if samplesIn and eventsIn were
        % empty
        if ~isempty(dv.trial.eyelink.samplesIn) || ~isempty(dv.trial.eyelink.eventsIn)
            dv.trial.eyelink.drained = false;
        end
        
    end
   dv.trial.eyelink.drained = false;
end