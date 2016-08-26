function p = play(p,sound_name,repeats)
%pds.behavior.audio.play(p,sound_name,repeats) play the sound associated with the
%specified name a specified number of times
%
%  In pds.behavior.audio.setup the tones in beepsounds were loaded and the
%  handles to the virtual sound devices were stored in
%  p.trial.sound.wavfiles as a series of fields which here we can reference
%  as p.trial.sound.wavfiles.(sound_name)
%
%  For now this function will do the following: First stop any sounds
%  currently playing on the device. Second play the desired sound. Third
%  return the start time of the sound.
%
%  NOTE:  this should be very simple, but one could if desired do more
%  complicated things such as superimpose sounds and use schedules for the
%  sounds much like DataPixx output schedules.
%
%  Edits by Lee Lovejoy 2016

%  Virtual device handle
[~,name] = fileparts(p.trial.sound.wavfiles.(sound_name));
pahandle = p.trial.sound.(name);

%  Find out if there is currently a sound playing on that device
status = PsychPortAudio('GetStatus',pahandle);

%  If there is a sound playing then stop it.
if(status.Active~=0)
    PsychPortAudio('Stop',pahandle);
end

%  Play the requested sound
%  Switch operation based on whether or not repeats is defined as a
%  variable
if(exist('repeats','var'))
    if(isinf(repeats))
        repeats = 0;
    end
else
    repeats = 1;
end
PsychPortAudio('Start',pahandle,repeats);