function dv = pdsEyelinkGetQueue(dv)
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
if dv.useEyelink
    % if time to pull samples, get them all
    while ~dv.el.drained
        [dv.el.samplesIn, dv.el.eventsIn, dv.el.drained] = Eyelink('GetQueuedData');
        
        % Get Eyelink samples
        if ~isempty(dv.el.samplesIn)
            dv.el.sampleBuffer(:,dv.el.sampleNum:dv.el.sampleNum+size(dv.el.samplesIn,2)-1) = dv.el.samplesIn;
            dv.el.sampleNum = dv.el.sampleNum+size(dv.el.samplesIn,2);
        end
        
        % Get Eyelink events
        if ~isempty(dv.el.eventsIn)
            dv.el.eventBuffer(:,dv.el.eventNum:dv.el.eventNum+size(dv.el.eventsIn,2)-1) = dv.el.eventsIn;
            dv.el.eventNum = dv.el.eventNum+size(dv.el.eventsIn,2);
        end
        
        % Workaround - only continue if samplesIn and eventsIn were
        % empty
        if ~isempty(dv.el.samplesIn) || ~isempty(dv.el.eventsIn)
            dv.el.drained = false;
        end
        
    end
    dv.el.drained = false;
end