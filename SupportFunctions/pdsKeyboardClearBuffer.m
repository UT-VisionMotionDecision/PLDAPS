function dv = pdsKeyboardClearBuffer(dv)
% dv = pdsKeyboardClearBuffer(dv)
% we use KbQueuCheck to poll the keyboard on every while loop because it is
% much faster than KbCheck (~400µs instead of ~1.3ms)
KbQueueCreate(-1); % sets up queue for device -1
KbQueueStart();
KbQueueFlush();
[dv.trial.pressedQ dv.trial.firstPressQ]=KbQueueCheck(); % first call KbQueueCheck