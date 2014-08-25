function clearBuffer(dv)
% pdsAudioClearBuffer(dv)
if dv.trial.sound.use
    PsychPortAudio('Stop', dv.trial.sound.breakfix);
    PsychPortAudio('Stop', dv.trial.sound.reward);
    PsychPortAudio('Stop', dv.trial.sound.incorrect);
    PsychPortAudio('Stop', dv.trial.sound.cue);
end