function stop(p, sound_name)
% funtion pds.sound.stop(p, sound_name)
%
% Stop the sound associated with sound_name.
%   - No arguments out
%
% 2020-01-16  TBC  Migrated to pds.sound (from pds.audio) to be consistent with field name
% 2022-02-25  LPL (ll2833@columbia.edu) added functionality to deactivate
% all sounds if function called with one input argument (pldaps object).
%

if(nargin==1)
    names = fieldnames(p.trial.sound);
    for i=1:numel(names)
        pahandle = p.trial.sound.(names{i});
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