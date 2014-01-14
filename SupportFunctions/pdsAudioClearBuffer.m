function pdsAudioClearBuffer(dv)
% pdsAudioClearBuffer(dv)

PsychPortAudio('Stop', dv.pa.sound.breakfix);
PsychPortAudio('Stop', dv.pa.sound.reward);
PsychPortAudio('Stop', dv.pa.sound.incorrect);
PsychPortAudio('Stop', dv.pa.sound.cue);