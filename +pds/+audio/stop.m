function p = stop(p,sound_name)
%pds.behavior.audio.stop(p,sound_name) stop the sound associated with the
%specified name.
%
%  SEE NOTES FOR play

%  Virtual device handle
[~,name] = fileparts(p.trial.sound.wavfiles.(sound_name));
pahandle = p.trial.sound.(name);

%  Stop the requested sound
PsychPortAudio('Stop',pahandle);
end

