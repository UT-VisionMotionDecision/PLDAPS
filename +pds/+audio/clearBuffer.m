function clearBuffer(p)
%pds.audio.clearBuffer(p)    stops audio output of files setup with pds.audio.setup(p)


warning('~!~\nMigrate code from pds.audio to pds.sound\n')
pds.sound.clearBuffer(p);

end


% % % if p.trial.sound.use && isfield(p.trial.sound, 'wavfiles')
% % %     fn=fieldnames(p.trial.sound.wavfiles);
% % %     for iFile = 1:length(fn)
% % %         PsychPortAudio('Stop', p.trial.sound.(fn{iFile}));
% % %     end
% % % end