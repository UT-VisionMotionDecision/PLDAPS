function [drained, samplesIn, eventsIn] = clearBuffer(drained)
%pds.eyelink.clearBuffer    clear the eyelink buffer
%
% [drained, samplesIn, eventsIn] = pds.eyelink.clearBuffer(drained)

while ~drained
    [samplesIn, eventsIn, drained] = Eyelink('GetQueuedData');
    
    % Workaround - only continue if samplesIn and eventsIn were
    % empty
    if ~isempty(samplesIn) || ~isempty(eventsIn)
        drained = false;
    end
end
drained = false;