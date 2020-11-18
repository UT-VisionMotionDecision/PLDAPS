function clearBuffer(p)
% pds.keyboard.clearBuffer(p)   clear the keyboard queue
%
% we use KbQueuCheck to poll the keyboard on every while loop because it is
% much faster than KbCheck (~400?s instead of ~1.3ms)
%

if nargin>0
    KbQueueFlush(p.trial.keyboard.devIdx);
else
    KbQueueFlush();
end

% KbQueueCreate(-1); % sets up queue for device -1
% KbQueueStart();
% KbQueueFlush();
% [p.trial.keyboard.pressedQ,  p.trial.keyboard.firstPressQ]=KbQueueCheck(); % first call KbQueueCheck