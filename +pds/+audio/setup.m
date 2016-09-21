function p = setup(p)
%pds.audio.setup(p)    loads audiofiles at the beginning of an experiment
% sets up the PsychAudio buffer and wavfile e.g. used to signal the start of
% a trial for the subject.
%
% (c) jly 2012
%     jk  2015 changed to work with version 4.1 and changed to load all
%              wavfiles in the wavfiles directory
if p.trial.sound.use && isfield(p.trial, 'pldaps.dirs.wavfiles')
    % initalize
    InitializePsychSound;
    
    soundsDir = p.trial.pldaps.dirs.wavfiles;
    
    soundDirFiles=dir(soundsDir);
    soundDirFiles={soundDirFiles.name};
    soundFiles=find(~cellfun(@isempty,strfind(soundDirFiles,'.wav')));
    
    for iFile=soundFiles
       name= soundDirFiles{iFile};
       p.trial.sound.wavfiles.(name(1:end-4))=fullfile(soundsDir,name);
       
       [y, freq] = audioread(p.trial.sound.wavfiles.(name(1:end-4)));
       wav1 = y';
       nChannels1 = size(wav1, 1);
       p.trial.sound.(name(1:end-4)) = PsychPortAudio('Open', p.trial.sound.deviceid, [], 1, freq, nChannels1);
       
       PsychPortAudio('FillBuffer',p.trial.sound.(name(1:end-4)), wav1);
    end    
else
    p.trial.sound.use=false;
end