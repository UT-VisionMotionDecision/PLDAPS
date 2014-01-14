function [drained, samplesIn, eventsIn] = pdsEyelinkClearBuffer(drained)
% [drained, samplesIn, eventsIn] = EyelinkClearBuffer(drained)    

while ~drained
    [samplesIn, eventsIn, drained] = Eyelink('GetQueuedData');
    
    % Workaround - only continue if samplesIn and eventsIn were
    % empty
    if ~isempty(samplesIn) || ~isempty(eventsIn)
        drained = false;
    end
end
drained = false;