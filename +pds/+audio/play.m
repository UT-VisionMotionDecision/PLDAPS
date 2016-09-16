function p = play(p,sound_name,repeats)
%pds.audio.play(p,sound_name,repeats) play the sound associated with the
%name sound_name repeats number of times
%
%  In pds.audio.setup the tones in beepsounds were loaded and the handles
%  to the virtual sound devices were stored in p.trial.sound.wavfiles as a
%  series of fields which here we can reference as
%  p.trial.sound.wavfiles.(sound_name)
%
%  For now this function will do the following: First stop any sounds
%  currently playing on the device. Second play the desired sound.
%
%  NOTE:  this function is currently very simple, but one could, if
%  desired, add more complicated capabilities such as superimposing sounds
%  or using schedules for the sounds much like DataPixx output schedules.
%
%  Lee Lovejoy
%  ll2833@columbia.edu
%  August 2016

if(nargin<3)
    repeats = 1;
end

%  Virtual device handle
[~,name] = fileparts(p.trial.sound.wavfiles.(sound_name));
pahandle = p.trial.sound.(name);

%  Find out if there is currently a sound playing on that device
status = PsychPortAudio('GetStatus',pahandle);

%  If there is a sound playing then stop it.
if(status.Active~=0)
    PsychPortAudio('Stop',pahandle);
end

%  Play the requested sound repeats number of times
if(isinf(repeats))
    repeats = 0;
end
PsychPortAudio('Start',pahandle,repeats);