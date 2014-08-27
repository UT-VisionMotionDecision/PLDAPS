function p = audioSetup(p)
%
% sets up the PsychAudio buffer and wavfile used to signal the start of a
% trial for the subject.
%
% (c) jly 2012
if p.defaultParameters.sound.use && isField(p.defaultParameters, 'pldaps.dirs.wavfiles')
    p.defaultParameters.sound.use=true;
    soundsDir = p.defaultParameters.pldaps.dirs.wavfiles;
    % setup psychport audio JLY
    p.defaultParameters.sound.wavfiles.cue       = fullfile(soundsDir,'cue.wav');
    p.defaultParameters.sound.wavfiles.breakfix  = fullfile(soundsDir,'breakfix.wav');
    p.defaultParameters.sound.wavfiles.reward    = fullfile(soundsDir,'reward.wav');
    p.defaultParameters.sound.wavfiles.incorrect = fullfile(soundsDir,'incorrect.wav');
    
    
    
    % initalize
    InitializePsychSound;
    
    % go through sound files and open a buffer
    % BREAKFIX
    [y, freq, ig] = wavread(p.defaultParameters.sound.wavfiles.breakfix);
    wav1 = y';
    nChannels1 = size(wav1, 1);
    p.defaultParameters.sound.breakfix = PsychPortAudio('Open', [], [], 1, freq, nChannels1);
    % REWARD
    [y, freq, ig] = wavread(p.defaultParameters.sound.wavfiles.reward);
    wav2 = y';
    nChannels2 = size(wav2, 1);
    p.defaultParameters.sound.reward = PsychPortAudio('Open', [], [], 1, freq, nChannels2);
    % INCORRECT
    [y, freq, ig] = wavread(p.defaultParameters.sound.wavfiles.incorrect);
    wav3 = y';
    nChannels3 = size(wav3, 1);
    p.defaultParameters.sound.incorrect = PsychPortAudio('Open', [], [], 1, freq, nChannels3);
    % CUE
    [y, freq, ig] = wavread(p.defaultParameters.sound.wavfiles.cue);
    wav4 = y';
    nChannels4 = size(wav4, 1);
    p.defaultParameters.sound.cue = PsychPortAudio('Open', [], [], 1, freq, nChannels4);
    
    
    % fill buffer with wav in pa.wavFile
    PsychPortAudio('FillBuffer', p.defaultParameters.sound.breakfix, wav1);
    PsychPortAudio('FillBuffer', p.defaultParameters.sound.reward, wav2);
    PsychPortAudio('FillBuffer', p.defaultParameters.sound.incorrect, wav3);
    PsychPortAudio('FillBuffer', p.defaultParameters.sound.cue, wav4);
    
else
    p.defaultParameters.sound.use=false;
end