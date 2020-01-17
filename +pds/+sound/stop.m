function stop(p, sound_name)
% funtion pds.sound.stop(p, sound_name)
% 
% Stop the sound associated with sound_name.
%   - No arguments out
%
% 2020-01-16  TBC  Migrated to pds.sound (from pds.audio) to be consistent with field name
% 
%  Virtual device handle
[~,name] = fileparts(p.trial.sound.wavfiles.(sound_name));
pahandle = p.trial.sound.(name);

%  Stop the requested sound
PsychPortAudio('Stop',pahandle);
end

