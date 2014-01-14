function dv = pdsAudioSetup(dv)
%
% sets up the PsychAudio buffer and wavfile used to signal the start of a
% trial for the subject.
%
% (c) jly 2012
if isfield(dv.pref, 'wavfiles')
    dv.sound = true;
    soundsDir = dv.pref.wavfiles;
    % setup psychport audio JLY
    dv.pa.wavfiles.cue       = fullfile(soundsDir,'cue.wav');
    dv.pa.wavfiles.breakfix  = fullfile(soundsDir,'breakfix.wav');
    dv.pa.wavfiles.reward    = fullfile(soundsDir,'reward.wav');
    dv.pa.wavfiles.incorrect = fullfile(soundsDir,'incorrect.wav');
    
    
    
    % initalize
    InitializePsychSound;
    
    % go through sound files and open a buffer
    % BREAKFIX
    [y, freq, ig] = wavread(dv.pa.wavfiles.breakfix);
    wav1 = y';
    nChannels1 = size(wav1, 1);
    dv.pa.sound.breakfix = PsychPortAudio('Open', [], [], 1, freq, nChannels1);
    % REWARD
    [y, freq, ig] = wavread(dv.pa.wavfiles.reward);
    wav2 = y';
    nChannels2 = size(wav2, 1);
    dv.pa.sound.reward = PsychPortAudio('Open', [], [], 1, freq, nChannels2);
    % INCORRECT
    [y, freq, ig] = wavread(dv.pa.wavfiles.incorrect);
    wav3 = y';
    nChannels3 = size(wav3, 1);
    dv.pa.sound.incorrect = PsychPortAudio('Open', [], [], 1, freq, nChannels3);
    % CUE
    [y, freq, ig] = wavread(dv.pa.wavfiles.cue);
    wav4 = y';
    nChannels4 = size(wav4, 1);
    dv.pa.sound.cue = PsychPortAudio('Open', [], [], 1, freq, nChannels4);
    
    
    % fill buffer with wav in pa.wavFile
    PsychPortAudio('FillBuffer', dv.pa.sound.breakfix, wav1);
    PsychPortAudio('FillBuffer', dv.pa.sound.reward, wav2);
    PsychPortAudio('FillBuffer', dv.pa.sound.incorrect, wav3);
    PsychPortAudio('FillBuffer', dv.pa.sound.cue, wav4);
    
else
    dv.sound = false;
end