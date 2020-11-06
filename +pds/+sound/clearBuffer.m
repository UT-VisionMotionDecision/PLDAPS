function clearBuffer(p)
% function pds.sound.clearBuffer(p)
% 
% Stops audio output of files setup with pds.audio.setup(p)
%   - No return arguments
% 
% 2020-01-16  TBC  Migrated to pds.sound (from pds.audio) to be consistent with field name
% 

if p.trial.sound.use && isfield(p.trial.sound, 'wavfiles')
    fn=fieldnames(p.trial.sound.wavfiles);
    for iFile = 1:length(fn)
        PsychPortAudio('Stop', p.trial.sound.(fn{iFile}));
    end
end