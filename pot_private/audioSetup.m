function dv = audioSetup(dv)
%
% sets up the PsychAudio buffer and wavfile used to signal the start of a
% trial for the subject.
%
% (c) jly 2012
if isField(dv.defaultParameters, 'pldaps.dirs.wavfiles')
    dv.defaultParameters.sound.use=true;
    soundsDir = dv.defaultParameters.pldaps.dirs.wavfiles;
    % setup psychport audio JLY
    dv.defaultParameters.sound.wavfiles.cue       = fullfile(soundsDir,'cue.wav');
    dv.defaultParameters.sound.wavfiles.breakfix  = fullfile(soundsDir,'breakfix.wav');
    dv.defaultParameters.sound.wavfiles.reward    = fullfile(soundsDir,'reward.wav');
    dv.defaultParameters.sound.wavfiles.incorrect = fullfile(soundsDir,'incorrect.wav');
    
    
    
    % initalize
    InitializePsychSound;
    
    % go through sound files and open a buffer
    % BREAKFIX
    [y, freq, ig] = wavread(dv.defaultParameters.sound.wavfiles.breakfix);
    wav1 = y';
    nChannels1 = size(wav1, 1);
    dv.defaultParameters.sound.breakfix = PsychPortAudio('Open', [], [], 1, freq, nChannels1);
    % REWARD
    [y, freq, ig] = wavread(dv.defaultParameters.sound.wavfiles.reward);
    wav2 = y';
    nChannels2 = size(wav2, 1);
    dv.defaultParameters.sound.reward = PsychPortAudio('Open', [], [], 1, freq, nChannels2);
    % INCORRECT
    [y, freq, ig] = wavread(dv.defaultParameters.sound.wavfiles.incorrect);
    wav3 = y';
    nChannels3 = size(wav3, 1);
    dv.defaultParameters.sound.incorrect = PsychPortAudio('Open', [], [], 1, freq, nChannels3);
    % CUE
    [y, freq, ig] = wavread(dv.defaultParameters.sound.wavfiles.cue);
    wav4 = y';
    nChannels4 = size(wav4, 1);
    dv.defaultParameters.sound.cue = PsychPortAudio('Open', [], [], 1, freq, nChannels4);
    
    
    % fill buffer with wav in pa.wavFile
    PsychPortAudio('FillBuffer', dv.defaultParameters.sound.breakfix, wav1);
    PsychPortAudio('FillBuffer', dv.defaultParameters.sound.reward, wav2);
    PsychPortAudio('FillBuffer', dv.defaultParameters.sound.incorrect, wav3);
    PsychPortAudio('FillBuffer', dv.defaultParameters.sound.cue, wav4);
    
else
    dv.defaultParameters.sound.use=false;
end