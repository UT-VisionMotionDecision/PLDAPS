function p = setup(p)
%pds.audio.setup(p)    loads audiofiles at the beginning of an experiment
% sets up the PsychAudio buffer and wavfile e.g. used to signal the start of
% a trial for the subject.
%
% (c) jly 2012
%     jk  2015 changed to work with version 4.1 and changed to load all
%              wavfiles in the wavfiles directory
%     jly 2016 changed to handle audio slaves - deals with bug on linux
if p.trial.sound.use && isField(p.trial, 'pldaps.dirs.wavfiles')

    % Prevent [infinite] hang that somtimes occurs during pldaps startup --TBC Oct. 2017
    PsychPortAudio('Close');
    
    % initalize
    InitializePsychSound;
    
    soundsDir = p.trial.pldaps.dirs.wavfiles;
    
    soundDirFiles=dir(soundsDir);
    soundDirFiles={soundDirFiles.name};
    soundFiles=find(~cellfun(@isempty,strfind(soundDirFiles,'.wav')));
    
    % open a PsychPortAudio master device. Master devices themselves are
    % not directly used to playback or capture sound. Instead one can
    % create (multiple) slave devices that are attached to a master device.
    % Each slave can be controlled independently to playback or record
    % sound through a subset of the channels of the master device. This
    % basically allows to virtualixe a soundcard.
    nchan = 2;
    
    if isempty(p.trial.sound.deviceid)
        p.trial.sound.deviceid = 0;
    end
    dev = PsychPortAudio('GetDevices', [], p.trial.sound.deviceid);
    p.trial.sound.master = PsychPortAudio('Open', p.trial.sound.deviceid, 1+8, 1, dev.DefaultSampleRate, nchan);
        
    % set the volume of the master to half the system volume
    PsychPortAudio('Volume', p.trial.sound.master, 0.85);

    % start master device
    PsychPortAudio('Start', p.trial.sound.master, 0, 0, 1);

    % open slave devices for each audio file
    for iFile=soundFiles
        name= soundDirFiles{iFile};
        p.trial.sound.wavfiles.(name(1:end-4))=fullfile(soundsDir,name);
        
        [y, ~] = audioread(p.trial.sound.wavfiles.(name(1:end-4)));
        if size(y,2)<nchan
            % mono to stereo
            y = repmat(y',nchan,1);
        else
            y = y(:,1:nchan)';
        end
        p.trial.sound.(name(1:end-4)) = PsychPortAudio('OpenSlave', p.trial.sound.master, 1, nchan);
        
        PsychPortAudio('FillBuffer',p.trial.sound.(name(1:end-4)), y);
    end
else
    p.trial.sound.use=false;
end