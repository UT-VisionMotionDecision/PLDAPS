function stop(p, sound_name)
% funtion pds.sound.stop(p, sound_name)
%
% Stop the sound associated with sound_name.
%   - No arguments out
%
% 2020-01-16  TBC  Migrated to pds.sound (from pds.audio) to be consistent with field name
% 2022-02-25  LPL (ll2833@columbia.edu) added functionality to deactivate
% all sounds if function called with one input argument.
%

if(nargin==1)
    fields = fieldnames(p.trial.sound.wavfiles);
    for i=1:numel(fields)
        [~,name] = fileparts(p.trial.sound.wavfiles.(fields{i}));
        pahandle = p.trial.sound.(name);
        status = PsychPortAudio('getStatus',pahandle);
        if(status.Active~=0)
            PsychPortAudio('Stop',pahandle);
        end
    end
else
    
    %  Virtual device handle
    [~,name] = fileparts(p.trial.sound.wavfiles.(sound_name));
    pahandle = p.trial.sound.(name);
    
    %  Stop the requested sound
    PsychPortAudio('Stop',pahandle);
end

end