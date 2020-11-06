function [drained, samplesIn, eventsIn] = clearBuffer(drained)
%pds.eyelink.clearBuffer    clear the eyelink buffer
%
% [drained, samplesIn, eventsIn] = pds.eyelink.clearBuffer(drained)
% 
% 2019-07-23  TBC  Made input optional. (...this fxn & outputs are odd)

if nargin<1
    drained = false;
end

while ~drained
    [samplesIn, eventsIn, drained] = Eyelink('GetQueuedData');
    
    % Workaround - only continue if samplesIn and eventsIn were
    % empty
    if ~isempty(samplesIn) || ~isempty(eventsIn)
        drained = false;
    end
end
drained = false;