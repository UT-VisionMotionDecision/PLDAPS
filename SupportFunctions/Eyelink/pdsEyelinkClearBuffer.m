function [drained, samplesIn, eventsIn] = pdsEyelinkClearBuffer(drained)
% [drained, samplesIn, eventsIn] = pdsEyelinkClearBuffer(drained)    
%
% pdsEyelinkClearBuffer clears values from the eyelink buffer. Should be
% run before each trial starts. 
% INPUTS
%       drained     - boolean for whether buffer has been drained
% OUTPUTS
%       drained     - modified boolean
%       samplesIn   - samples recorded from buffer
%       eventsIn    - events recorded from buffer

% 12/2013 jly   wrote it

while ~drained
    [samplesIn, eventsIn, drained] = Eyelink('GetQueuedData');
    
    % Workaround - only continue if samplesIn and eventsIn were
    % empty
    if ~isempty(samplesIn) || ~isempty(eventsIn)
        drained = false;
    end
end
drained = false;