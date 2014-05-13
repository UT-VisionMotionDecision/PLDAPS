function audioClearBuffer(dv)
% pdsAudioClearBuffer(dv)

PsychPortAudio('Stop', dv.trial.sound.breakfix);
PsychPortAudio('Stop', dv.trial.sound.reward);
PsychPortAudio('Stop', dv.trial.sound.incorrect);
PsychPortAudio('Stop', dv.trial.sound.cue);