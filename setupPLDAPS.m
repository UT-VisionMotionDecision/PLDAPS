%% Setup PLDAPS README
% This script is here to guide you in setting up PLDAPS environments.
% PLDAPS V3 takes advantage of matlab's built in preferences. Here we add a
% group, 'PLDAPS', and the requisite preferences for using the rest of the
% scripts.

%% Step 1 (required) LOCAL COPY
%-------------------------------------------------------------------------%
% Setup a preference group called 'PLDAPS' with the preference 'base' that
% points to the local copy of PLDAPS as it was downloaded from the git
% repository.

pldapsBase = '/Users/monkeyrig/PLDAPS/PLDAPSV3';

setpref('PLDAPS','base',pldapsBase);

disp(['Setting PLDAPS directory preference to: ' pldapsBase]);
disp('Use the folowing command to change:');
disp('setpref(''PLDAPS'',''base'',/path/to/PLDAPS); ');

%% Step 2 (required) RIG CONFIG FILE
%-------------------------------------------------------------------------%
% the rig config file replaces setupPLDAPS. It specifies the use of overlay
% pointers, the screen size, and the gamma correction for your rig.
% modify pointer to where you local RigConfigFiles are
pldapsRig = '/Users/monkeyrig/PLDAPS/RigConfigFiles/lg55_viewdist118.mat';

setpref('PLDAPS','rig',pldapsRig);

disp(['Setting PLDAPS rig to: ' pldapsRig]);
disp('Use the folowing command to change:');
disp('setpref(''PLDAPS'',''rig'',/path/to/rig); ');

%% Step 3 (required) DATA DIRECTORY
%-------------------------------------------------------------------------%
% This points to the default directory where PLDAPS gets saved. Make sure
% that you have a TEMP folder inside this directory. Lots of files will get
% dumped here during recording.

% Data gets saved where
pldapsData = '/Data';

setpref('PLDAPS','datadir',pldapsData);
disp(['Setting PLDAPS data directory preference to: ' pldapsData]);
disp('Use the folowing command to change:');
disp('setpref(''PLDAPS'',''datadir'',/path/to/Data); ');


%% Step 4 (optional) SPIKESERVER PREFERENCES
%-------------------------------------------------------------------------%
% If you want to use spikeserver (udp protocol for plexon map servers) to
% transfer spikes from the MAP server directly to the display computer over
% ethernet, see the help section in the spikeserver code.

spikeserver.remoteip = '129.116.159.110';  % Plexon IP address
spikeserver.remoteport = 3332;             % can be any unused port
spikeserver.selfip = '129.116.159.104';    % this computer's IP
spikeserver.selfport = 3332;               % must be same as remoteport

setpref('PLDAPS','spikeserver',spikeserver);

%% Step 5 (optional) SOUND WAV FILES
%-------------------------------------------------------------------------%
% If you want to play sound using PsychPortAudio, this should point to the
% directory where your wave files live. It's kind of unnecessary because
% you can customize this later in the condition files.
soundir = '~/PLDAPS/beepsounds/';

setpref('PLDAPS','wavfiles',soundir);
disp(['Setting PLDAPS data directory preference to: ' soundir]);
disp('Use the folowing command to change:');
disp('setpref(''PLDAPS'',''wavfiles'',/path/to/Data); ');



